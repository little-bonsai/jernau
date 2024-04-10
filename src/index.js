#!/usr/bin/env node

import arg from "arg";
import * as fs from "fs/promises";
import pathLib from "path";
import inkjs from "inkjs";
const { Story } = inkjs;

function* runOnce(args, storySource) {
  const story = new Story(storySource);
  story.allowExternalFunctionFallbacks = true;
  let currentPathString = story.state.currentPathString;

  try {
    while (story.canContinue || story.currentChoices.length !== 0) {
      currentPathString = story.state.currentPathString || currentPathString;

      if (currentPathString === args["--done-path"]) {
        return;
      } else if (story.canContinue) {
        story.Continue();
        yield { out: story.currentText };
      } else if (story.currentChoices.length > 0) {
        const index = (Math.random() * story.currentChoices.length) | 0;

        yield { out: story.currentChoices[index].text };
        story.ChooseChoiceIndex(index);
        story.Continue();
      } else {
        yield { fail: 0, story, currentPathString };
      }
    }
  } catch (fail) {
    yield { fail, story, currentPathString };
  }
}

async function main(args) {
  const storySource = await fs.readFile(args["--ink"], "utf8");

  let run = 0;
  const runs = args["--itterations"] || Math.sqrt(storySource.length) | 0;

  let lineBuffer = [];

  outer: while (run++ < runs) {
    for (const thing of runOnce(args, storySource)) {
      if ("out" in thing) {
        if (args["--silent"]) {
          lineBuffer.push(thing.out.trim());
          lineBuffer = lineBuffer.slice(-Math.sqrt(runs));
        } else {
          console.log(thing.out.trim());
        }
      }

      if ("fail" in thing) {
        console.log("");
        if (args["--silent"]) {
          console.log("...");
          console.log(lineBuffer.join("\n"));
          console.log("");
        }

        console.log("fail", "@", thing.currentPathString);
        if (thing.fail) {
          console.log(thing.fail);
        }

        break outer;
      }
    }

    console.log(run.toString().padStart(6, " ") + "/" + runs.toString());
  }
}

const argSpec = {
  // General
  "--help": Boolean,
  "--version": Boolean,
  "--verbose": arg.COUNT, // Counts the number of times --verbose is passed

  "--silent": Boolean,
  "--ink": String,
  "--externals": String,
  "--itterations": Number,
  "--done-path": String,
};

function printHelp() {
  console.log(
    `
Jernau
A CLI for testing .ink files

Usage:
         $ jernau --ink story.json

Arguments:
        --help
        --version
        --verbose
    
        --done-path      : Ink path that marks a successful end of the story
        --externals      : Path to the js module that exports the required externals
        --ink            : Path to the story.json file to run
        --itterations    : How many times to run
        --silent         : Do not print story output as it runs
`.trim(),
    "\n",
  );
}

main(arg(argSpec, { permissive: true, argv: process.argv.slice(2) }));

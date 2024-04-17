#!/usr/bin/env node

import arg from "arg";
import * as fs from "fs";
import pathLib from "path";
import inkjs from "inkjs";
import { getIntRange, gen } from "./random.mjs";
const { Story } = inkjs;

function* runOnce(args, validators, seed, storySource) {
  const story = new Story(storySource);
  story.allowExternalFunctionFallbacks = true;
  let currentPathString = story.state.currentPathString;
  const rand = gen(seed);
  story.state.storySeed = seed;

  try {
    while (story.canContinue || story.currentChoices.length !== 0) {
      currentPathString = story.state.currentPathString || currentPathString;

      if (validators.isDone(story)) {
        return;
      } else if (story.canContinue) {
        story.Continue();
        yield { out: story.currentText };
      } else if (story.currentChoices.length > 0) {
        const index = getIntRange(0, story.currentChoices.length, gen());

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

  if (validators.isDone(story)) {
    return;
  } else {
    yield {
      fail: "run out of content, but validators.isDone returned false",
      story,
      currentPathString,
    };
  }
}

async function main(mainPath, args) {
  if (args["--help"]) throw "print help";
  if (!args["--ink"]) throw new Error("missing required argument: --ink");
  if (!args["--validators"])
    throw new Error("missing required argument: --validators");

  const validators = await import(
    pathLib.join(process.cwd(), args["--validators"])
  );
  const storySource = fs.readFileSync(args["--ink"], "utf8");

  let run = 0;
  const runs = args["--itterations"] || Math.sqrt(storySource.length) | 0;

  let lineBuffer = [];

  outer: while (run++ < runs) {
    for (const thing of runOnce(args, validators, run, storySource)) {
      if ("out" in thing) {
        if (args["--verbose"]) {
          console.log(thing.out.trim());
        } else {
          lineBuffer.push(thing.out.trim());
          lineBuffer = lineBuffer.slice(-Math.sqrt(runs));
        }
      }

      if ("fail" in thing) {
        console.log("");
        if (!args["--verbose"]) {
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
  "--verbose": arg.COUNT, // Counts the number of times --verbose is passed

  "--ink": String,
  "--itterations": Number,
  "--validators": String,
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
    
        --validators     : Path to the js module that exports the required validators
        --ink            : Path to the story.json file to run
        --itterations    : How many times to run
`.trim(),
    "\n",
  );
}

(async () => {
  try {
    await main(
      process.argv[1],
      arg(argSpec, { permissive: true, argv: process.argv.slice(2) }),
    );
  } catch (e) {
    console.error(e);
    printHelp();
  }
})();

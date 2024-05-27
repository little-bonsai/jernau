#!/usr/bin/env node

import arg from "arg";
import * as fs from "fs";
import pathLib from "path";
import { Story } from "inkjs/dist/ink-es6.mjs";
import { getIntRange, gen } from "./random.mjs";
import chalk from "chalk";

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
        if (validators.lineValid) {
          const validation = validators.lineValid(story.currentText, story);
          const { isValid, msg } = validation;
          if (!isValid) {
            yield { kind: "text", out: story.currentText };
            throw msg;
          }
        }
        yield { kind: "text", out: story.currentText };
      } else if (story.currentChoices.length > 0) {
        const index = getIntRange(0, story.currentChoices.length, rand());

        yield {
          kind: "options",
          out: story.currentChoices,
          index,
        };
        story.ChooseChoiceIndex(index);
      } else {
        yield { kind: "text", out: story.currentText };
        yield { kind: "fail", fail: 0, story, currentPathString };
      }
    }
  } catch (fail) {
    yield { kind: "text", out: story.currentText };
    yield { kind: "fail", fail, story, currentPathString };
  }

  if (validators.isDone(story)) {
    return;
  } else {
    yield { kind: "text", out: story.currentText };
    yield {
      kind: "fail",
      fail: "run out of content, but validators.isDone returned false",
      story,
      currentPathString,
    };
  }
}

function printEvent(evt) {
  switch (evt.kind) {
    case "text": {
      console.log(evt.out.trim());
      return;
    }

    case "options": {
      for (const i in evt.out) {
        const option = evt.out[i];
        if (i == evt.index) {
          console.log(chalk.green(i.padStart(4, " "), "->", option.text));
        } else {
          console.log(chalk.blue(i.padStart(4, " "), "  ", option.text));
        }
      }
      return;
    }

    default: {
      console.log("I DON'T KNOW HOW TO PRINT THIS", evt);
    }
  }
}

function runForSeed({ seed, args, runs, validators, storySource }) {
  let lineBuffer = [];

  for (const evt of runOnce(args, validators, seed, storySource)) {
    if (evt.kind === "fail") {
      console.log("");

      if (!args["--verbose"]) {
        console.log(chalk.cyan("..."));
        lineBuffer.map(printEvent);
        console.log("");
      }

      console.log(chalk.red("fail", "@", evt.currentPathString));

      if (evt.fail) {
        console.log(chalk.red(evt.fail));
      }

      return true;
    }

    if (args["--verbose"]) {
      printEvent(evt);
    } else {
      lineBuffer.push(evt);
      lineBuffer = lineBuffer.slice(-Math.sqrt(Math.sqrt(storySource.length)));
    }
  }

  console.log(seed.toString().padStart(6, " ") + "/" + runs.toString());
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

  if (args["--seed"]) {
    runForSeed({
      seed: args["--seed"],
      args,
      runs: 1,
      validators,
      storySource,
    });
  } else {
    let seed = 0;
    const runs = args["--itterations"] || Math.sqrt(storySource.length) | 0;

    while (seed++ < runs) {
      if (runForSeed({ seed, args, runs, validators, storySource })) {
        break;
      }
    }
  }
}

const argSpec = {
  // General
  "--help": Boolean,
  "--verbose": arg.COUNT, // Counts the number of times --verbose is passed

  "--ink": String,
  "--itterations": Number,
  "--seed": Number,
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
    
        --ink            : Path to the story.json file to run
        --itterations    : How many times to run
        --seed           : run a single seeded playthrough
        --validators     : Path to the js module that exports the required validators
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

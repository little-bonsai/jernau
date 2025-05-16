/* const {
  Worker, isMainThread, parentPort, workerData,
} = require('node:worker_threads');
*/

type t<'a>

type options
@obj external options: (~name: string=?) => options = ""

@module("node:worker_threads") @val external isMainThread: bool = "isMainThread"
@module("node:worker_threads") @val external parentPort: t<'a> = "parentPort"
@module("node:worker_threads") @new external make: (string, options) => t<'a> = "Worker"

@send external onMessage: (t<'a>, @as("message") _, 'a => promise<unit>) => unit = "on"
@send external onError: (t<'a>, @as("error") _, 'a => unit) => unit = "on"
@send external onExit: (t<'a>, @as("error") _, int => unit) => unit = "on"
@send external postMessage: (t<'a>, 'a) => unit = "postMessage"

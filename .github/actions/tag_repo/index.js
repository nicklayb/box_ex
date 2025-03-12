import * as core from '@actions/core'
import { context, getOctokit } from '@actions/github'
import { readFile } from 'node:fs/promises'

const VERSION_FILE = './VERSION'

let octokitSingleton = null

function getOctokitSingleton() {
  if (octokitSingleton) {
    return octokitSingleton;
  }
  const githubToken = core.getInput('token');
  octokitSingleton = getOctokit(githubToken);
  return octokitSingleton;
}
async function getTag() {
  const result = await getOctokitSingleton().repos.getReleaseByTag({
    ...context.repo,
    tag_sha: version
  })
  console.log({ result })
}

async function run() {
  try {
    const content = await readFile(VERSION_FILE, { encoding: "utf8" })
    const version = content.trim()

    await getTag();

  } catch (error) {
    core.setFailed(error.message);
  }
}

run()

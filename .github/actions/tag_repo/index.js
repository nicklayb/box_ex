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

async function getTag(version) {
  const octoKit = getOctokitSingleton()
  try {
    core.info("Fetching tag")
    const result = await octoKit.rest.repos.getReleaseByTag({
      ...context.repo,
      tag: version
    })
    console.log({ result })
    return result.data.id
  } catch (_error) {
    core.info("Could not find tag")

    return null
  }
}

async function createTag(tag) {
  const octoKit = getOctokitSingleton()
  const result = await octoKit.rest.repos.createTag({
    ...context.repo,
    tag,
    message: `v${tag}`,
    object: context.sha,
    type: 'commit',
  })
  console.log({ create: result })
}

async function run() {
  try {
    const content = await readFile(VERSION_FILE, { encoding: "utf8" })
    const version = content.trim()

    const gitHubTag = await getTag(version)

    if (gitHubTag !== null) {
      core.info(`Tag ${version} already exists`)
    } else {
      core.info("Could not find tag, creating...")
      await createTag(version)
    }


  } catch (error) {
    core.setFailed(error.message);
  }
}

run()

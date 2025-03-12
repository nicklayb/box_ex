import core, { getInput } from '@actions/core'
import { context, getOctokit } from '@actions/github'
import { readFile } from 'node:fs/promises'

const VERSION_FILE = './VERSION'

try {
  readFile(VERSION_FILE, { encoding: "utf8" }).then(content => {
    const version = content.trim()
    const token = getInput("token")

    getOctokit(token).rest.repos.getReleaseByTag({
      ...context.repo,
      tag_sha: version
    }).then(result => {
      console.log({ result })
    }).catch(error => {
      console.log({ error })
    })

    console.log(version)

    core.setOutput('version', version)
  })
} catch (error) {
  core.setFailed(error.message);
}

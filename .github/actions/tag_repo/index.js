import core from '@actions/core'
import github from '@actions/github'
import { readFile } from 'node:fs/promises'

const VERSION_FILE = './VERSION'

try {
  readFile(VERSION_FILE, { encoding: "utf8" }).then(content => {
    const version = content.trim()

    core.setOutput('version', version)
  })
} catch (error) {
  core.setFailed(error.message);
}

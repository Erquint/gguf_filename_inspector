# GGUF Filename Inspector

A CLI utility that takes a single string, which must be a GGUF filename, and spits out an explanation of the metadata encoded into it.  
Effort was made to approach a degree of accessibility. The output should be screen-reader- and TTS-friendly.  
Entry-level jargon is used in produced descriptions, the sort one could easily look up or ask friends about. Not getting into weeds.  

## Installation

- Use a prebuilt portable binary executable from the releases section if you have trust.
- Read and build the sources with Crystal if you don't.

## Usage

### Schema

`<executable_filename> <gguf_filename>`

### Example

`gguf_filename_inspector Mixtral-8x7B-v0.1-KQ2.gguf`

### Requirements

No GGUF files are required to be present in the filesystem — the utility just inspects a string you pass as text.

## Feedback

Open an issue if you have suggestion on improving accessibility as long as they are reasonably within the theme and scope of the project.  
Or stuff, you know…

## Development

Do whatever spider can.

## License

This work is published under Unlicense, which is a public domain dedication waiver.  
You can do whatever you want with it.

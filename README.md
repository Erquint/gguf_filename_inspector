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

### Requirements

No GGUF files are required to be present in the filesystem — the utility just inspects a string you pass as text.

### Example input

`gguf_filename_inspector Mixtral-8x7B-v0.1-KQ2.gguf`

### Example output

This is a made-up model quant filename intended to cover many metadata features.

```plain
> .\gguf_file_inspector.exe mtp-gemma-4-V-26B-A4B-it.i1-Q4_K_M-00002-of-00201.gguf
Model producer section.
  This is a sidecar file meant to be used in addition to the main model file.
    mtp : Multiple token prediction sidecar for speculative decoding.
  Instruct-based post-training narrows a model's capability to reliably perform in structured chat or agentic context.
    it : This is a model instruct-tuned on structured data.
  Some models support multimodality or even so-called "omnimodality" to perceive non-textual media when loaded with a multimodal projector.
    V : This filename may suggest this model can see visually if a multimodal sidecar "mmproj" file is loaded alongside.
  The notional size of the model before quantization reflects capability, disk storage and memory requirements.
    26B : 26 billion total parameters in this model. The number is 26 billion parameters.
  This is a sparse Mixture of Experts model. Only a subset of its parameters require computational effort.
    A4B : 4 billion parameters actively processed at any given time during inference. The number is 4 billion parameters.
GGUF quantizer section.
  Quantized model weights may be represented with different numerical structures in memory.
    Q4_K : The algorithm and memory structure used in this file is K-Quant.
  The number of bits allocated per each weight defines fidelity preserved in quantizing this model file.
    Q4_K : The first number suggests that most of the weights in this model are encoded with 4 BPW (bits per weight). The number is 4 BPW.
  Within each level of overall quantization, there is slack for subvariants to be slightly larger or smaller.
    _M : A medium subvariant at this bits-per-weight level.
  Distribution of relative fidelity among weights may further be prioritized towards ones prevalent in a given dataset.
    i1 : Weights compression fidelity distributed according to importance matrix calibration using mradermacher dataset.
  Very large files may be split into parts called "shards."
    00002-of-00201 : This is shard 2 of 201. The numbers are 2 of 201.
```

## Feedback

Open an issue if you have suggestion on improving accessibility as long as they are reasonably within the theme and scope of the project.

Or, you know, stuff…

Don't expect a quick reaction.

## Development

Do whatever spider can.

### Building

My binaries built with something like:

```sh
crystal build --static --release --no-debug --stats --progress --time --verbose --output ./bin/x86_64-pc-windows-msvc/gguf_file_inspector.exe ./src/interface.cr
```

```sh
crystal build --static --release --no-debug --stats --progress --time --verbose --output ./bin/x86_64-unknown-linux-gnu/gguf_file_inspector ./src/interface.cr
```

On respective platforms, natively. Cross-compilation didn't work from Windows for me.

### Testing

There is a specfile for tests. I let Kimi AI make it. Could be useful to run if you modify the program, like this…

```sh
crystal spec .\spec\gguf_filename_inspector_spec.cr
```

Or even simpler…

```sh
crystal spec
```


Or improve it, if you're into that sort of thing.

## Citations

The GGML spec is inconsistent and the scene doesn't follow it strictly, but here are some semi-useful links:

- <https://github.com/ggml-org/ggml/blob/master/docs/gguf.md>
- <https://github.com/ggml-org/llama.cpp/wiki/Tensor-Encoding-Schemes/>

## License

This work is published under Unlicense, which is a public domain dedication waiver.  
You can do whatever you want with it.

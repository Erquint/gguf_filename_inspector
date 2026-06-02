require "./spec_helper"

# These tests are AI-generated.

describe GGUFFilenameInspector do
  describe "mandatory extension guard" do
    it "accepts standard lowercase .gguf" do
      output = GGUFFilenameInspector.decode_filename("model.gguf")
      output.should contain("Model producer section")
    end

    it "accepts uppercase .GGUF if ends_with? truly honors the /i regex flag" do
      # Crystal String#ends_with? historically does not accept Regex.
      # If this compiles and passes, the guard is robust; if it fails to compile, that is the bug.
      output = GGUFFilenameInspector.decode_filename("model.GGUF")
      output.should contain("Model producer section")
    end
  end

  describe "reference filenames from the brief" do
    it "parses gemma-4-26B-A4B-it.i1-Q4_K_M.gguf end-to-end" do
      output = GGUFFilenameInspector.decode_filename("gemma-4-26B-A4B-it.i1-Q4_K_M.gguf")
      output.should contain("26 billion total parameters in this model")
      output.should contain("4 billion parameters actively processed")
      output.should contain("sparse Mixture of Experts")
      output.should contain("K-Quant")
      output.should contain("encoded with 4 BPW")
      output.should contain("A medium subvariant")
      output.should contain("mradermacher dataset")
    end

    it "parses gemma-4-26B-A4B-it-UD-Q4_K_M.gguf with Unsloth distribution" do
      output = GGUFFilenameInspector.decode_filename("gemma-4-26B-A4B-it-UD-Q4_K_M.gguf")
      output.should contain("Unsloth dataset")
      output.should contain("K-Quant")
    end

    it "parses gemma-3n-E4B-it.i1-Q4_K_S.gguf with small subvariant" do
      output = GGUFFilenameInspector.decode_filename("gemma-3n-E4B-it.i1-Q4_K_S.gguf")
      output.should contain("A small subvariant")
      output.should contain("K-Quant")
    end

    it "parses MiniCPM-V-4_5-i1-IQ3_S.gguf for I-Quant and vision hint" do
      output = GGUFFilenameInspector.decode_filename("MiniCPM-V-4_5-i1-IQ3_S.gguf")
      output.should contain("I-Quant")
      output.should contain("encoded with 3 BPW")
      output.should contain("may suggest this model can see visually")
    end

    it "parses mmproj-Pixtral-12B-2409-Q8_0.gguf as sidecar with Uniform quant" do
      output = GGUFFilenameInspector.decode_filename("mmproj-Pixtral-12B-2409-Q8_0.gguf")
      output.should contain("Multimodal projector sidecar")
      output.should contain("12 billion total parameters in this model")
      output.should contain("Uniform")
      output.should contain("encoded with 8 BPW")
    end

    it "parses Qwen3-TTS-12Hz-1.7B-Base-f16.gguf for decimal billions and Float" do
      output = GGUFFilenameInspector.decode_filename("Qwen3-TTS-12Hz-1.7B-Base-f16.gguf")
      output.should contain("1.7 billion total parameters in this model")
      output.should contain("Float")
      output.should contain("encoded with 16 BPW")
    end
  end

  describe "training stage markers" do
    it "detects IT as instruct-tuned" do
      output = GGUFFilenameInspector.decode_filename("model-26B-IT-Q4_K_M.gguf")
      output.should contain("instruct-tuned on structured data")
    end

    it "detects PT as pre-trained only" do
      output = GGUFFilenameInspector.decode_filename("model-26B-PT-Q4_K_M.gguf")
      output.should contain("pre-trained only on a vast corpus")
    end

    it "detects lowercase it as instruct-tuned because the regex is case-insensitive" do
      output = GGUFFilenameInspector.decode_filename("gemma-4-26B-it-Q4_K_M.gguf")
      output.should contain("instruct-tuned on structured data")
    end

    it "does not false-positive on it inside unrelated words like visit" do
      output = GGUFFilenameInspector.decode_filename("model-visit-26B-Q4_K_M.gguf")
      output.should_not contain("instruct-tuned")
    end
  end

  describe "vision capability hints" do
    it "detects -V separator token" do
      output = GGUFFilenameInspector.decode_filename("MiniCPM-V-4_5-i1-IQ3_S.gguf")
      output.should contain("may suggest this model can see visually")
    end

    it "detects -VL separator token" do
      output = GGUFFilenameInspector.decode_filename("model-VL-26B-Q4_K_M.gguf")
      output.should contain("may suggest this model can see visually")
    end

    it "detects .V separator token" do
      output = GGUFFilenameInspector.decode_filename("model.V.26B.Q4_K_M.gguf")
      output.should contain("may suggest this model can see visually")
    end

    it "does not match VL inside longer words without a trailing boundary" do
      output = GGUFFilenameInspector.decode_filename("model-VLLA-26B-Q4_K_M.gguf")
      output.should_not contain("may suggest this model can see visually")
    end
  end

  describe "separator tolerance where underscores become hyphens or periods" do
    it "detects Q4-K-M subvariant when hyphens replace underscores" do
      # The SUBVARIANT_SIZE_PREFIX hardcodes Q\\d+_K with a literal underscore.
      # If tolerance is real, Q4-K-M should still resolve to K-Quant plus medium subvariant.
      output = GGUFFilenameInspector.decode_filename("model-26B-Q4-K-M.gguf")
      output.should contain("K-Quant")
      output.should contain("A medium subvariant")
    end

    it "detects Q4.K.M subvariant when periods replace underscores" do
      output = GGUFFilenameInspector.decode_filename("model.26B.Q4.K.M.gguf")
      output.should contain("K-Quant")
      output.should contain("A medium subvariant")
    end

    it "detects sidecar mmproj when separated by underscores instead of hyphens" do
      # \\b treats underscore as a word character, so \\bmmproj\\b fails when followed by _.
      output = GGUFFilenameInspector.decode_filename("mmproj_model_26B_Q4_K_M.gguf")
      output.should contain("Multimodal projector sidecar")
    end

    it "detects total count when separated by underscores instead of hyphens" do
      output = GGUFFilenameInspector.decode_filename("model_26B_Q4_K_M.gguf")
      output.should contain("26 billion total parameters in this model")
    end

    it "detects sparse count when separated by underscores instead of hyphens" do
      output = GGUFFilenameInspector.decode_filename("model_A4B_Q4_K_M.gguf")
      output.should contain("4 billion parameters actively processed")
    end

    it "detects distribution i1 when separated by underscores instead of periods" do
      output = GGUFFilenameInspector.decode_filename("model_i1_Q4_K_M.gguf")
      output.should contain("mradermacher dataset")
    end
  end

  describe "shard parsing and zero-stripping" do
    it "strips leading zeros from identity and bound with standard hyphens" do
      output = GGUFFilenameInspector.decode_filename("model-00002-of-00201.gguf")
      output.should contain("shard 2 of 201")
    end

    it "tolerates periods in shard separators" do
      output = GGUFFilenameInspector.decode_filename("model-00002.of.00201.gguf")
      output.should contain("shard 2 of 201")
    end

    it "verbalizes shard zero identity without collapsing to empty string" do
      # lstrip('0') on "00000" returns "". The template then produces "shard of 1".
      output = GGUFFilenameInspector.decode_filename("model-00000-of-00001.gguf")
      output.should contain("shard 0 of 1")
    end

    it "verbalizes shard one identity without collapsing to empty string" do
      output = GGUFFilenameInspector.decode_filename("model-00001-of-00001.gguf")
      output.should contain("shard 1 of 1")
    end
  end

  describe "case sensitivity and SI scale robustness" do
    it "does not crash on lowercase SI postfixes like 26b" do
      # The total_count regex is case-insensitive (/i), but SI_POSTFIX hash only has uppercase keys.
      # A lowercase 'b' in the capture will raise KeyError unless upcased before lookup.
      output = GGUFFilenameInspector.decode_filename("model-26b-q4_k_m.gguf")
      output.should contain("26 billion total parameters in this model")
    end

    it "does not crash on lowercase sparse postfix like a4b" do
      output = GGUFFilenameInspector.decode_filename("model-a4b-q4_k_m.gguf")
      output.should contain("parameters actively processed")
    end

    it "detects mixed-case storage struct f16 as Float" do
      output = GGUFFilenameInspector.decode_filename("model-f16.gguf")
      output.should contain("Float")
      output.should contain("encoded with 16 BPW")
    end
  end

  describe "density classification" do
    it "declares dense monolith when no sparse count is present" do
      output = GGUFFilenameInspector.decode_filename("model-26B-Q4_K_M.gguf")
      output.should contain("dense monolith model")
      output.should_not contain("sparse Mixture of Experts")
    end

    it "declares sparse when A-count is present" do
      output = GGUFFilenameInspector.decode_filename("model-26B-A4B-Q4_K_M.gguf")
      output.should contain("sparse Mixture of Experts")
      output.should_not contain("dense monolith model")
    end

    it "emits exactly one density statement even if multiple sparse patterns existed" do
      output = GGUFFilenameInspector.decode_filename("model-26B-A4B-Q4_K_M.gguf")
      output.scan(/dense monolith/).size.should eq(0)
      output.scan(/sparse Mixture of Experts/).size.should eq(1)
    end
  end

  describe "storage struct specificity and priority" do
    it "prefers IQ over plain Q when both could match" do
      output = GGUFFilenameInspector.decode_filename("model-IQ3_S.gguf")
      output.should contain("I-Quant")
      output.should_not contain("Uniform")
    end

    it "detects Brain Float BF16" do
      output = GGUFFilenameInspector.decode_filename("model-BF16.gguf")
      output.should contain("Brain Float")
    end

    it "detects Integer I8" do
      output = GGUFFilenameInspector.decode_filename("model-I8.gguf")
      output.should contain("Integer")
    end

    it "detects Ternary T1" do
      output = GGUFFilenameInspector.decode_filename("model-T1.gguf")
      output.should contain("Ternary")
    end

    it "detects Microscaling Floating-Point MXFP8" do
      output = GGUFFilenameInspector.decode_filename("model-MXFP8.gguf")
      output.should contain("Microscaling Floating-Point")
    end

    it "detects Ancient Q4_0_0_0 format before Uniform can claim it" do
      output = GGUFFilenameInspector.decode_filename("model-Q4_0_0_0.gguf")
      output.should contain("Ancient")
    end

    it "describes F16 as Float format" do
      output = GGUFFilenameInspector.decode_filename("model-F16.gguf")
      output.should contain("Float")
    end
  end

  describe "subvariant size extremes" do
    it "detects XXS doubly-extra-small" do
      output = GGUFFilenameInspector.decode_filename("model-Q4_K_XXS.gguf")
      output.should contain("doubly-extra-small subvariant")
    end

    it "detects XXL doubly-extra-large" do
      output = GGUFFilenameInspector.decode_filename("model-Q4_K_XXL.gguf")
      output.should contain("doubly-extra-large subvariant")
    end

    it "detects XS extra-small" do
      output = GGUFFilenameInspector.decode_filename("model-Q4_K_XS.gguf")
      output.should contain("extra-small subvariant")
    end

    it "detects XL extra-large" do
      output = GGUFFilenameInspector.decode_filename("model-Q4_K_XL.gguf")
      output.should contain("extra-large subvariant")
    end
  end

  describe "first-match-wins semantics" do
    it "only reports the first total count match and ignores later billions" do
      output = GGUFFilenameInspector.decode_filename("model-26B-1.7B-Q4_K_M.gguf")
      output.should contain("26 billion total parameters in this model")
      output.should_not contain("1.7 billion total parameters in this model")
    end

    it "only reports the first training stage match" do
      output = GGUFFilenameInspector.decode_filename("model-PT-IT-Q4_K_M.gguf")
      output.should contain("pre-trained only")
      output.should_not contain("instruct-tuned")
    end
  end
end

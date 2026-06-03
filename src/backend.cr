module GGUFFilenameInspector
  VERSION = "0.1.0"
  
  SUBVARIANT_SIZE_PREFIX = "(?:IQ\\d+|Q\\d+[ ._-]K|KQ\\d+|F\\d+|BF\\d+|I\\d+|T\\d+|MXFP\\d+)"
  
  SI_POSTFIX = {
    'K' => "thousand",
    'M' => "million",
    'B' => "billion",
    'T' => "trillion",
    'Q' => "quadrillion",
  }
  
  PATTERNS = {
    :sidecar => {
      /(?<=[ ._-])mmproj(?=[ ._-])/i => "Multimodal projector sidecar for non-textual media support, such as vision, hearing, etc…",
      /(?<=[ ._-])mtp(?=[ ._-])/i    => "Multiple token prediction sidecar for speculative decoding.",
    },
    :total_count => {
      /(?<=[ ._-])E([\d.]+)[ ._-]?([KMBTQ])(?=[ ._-])/i           => "#NUMBER effective total parameters in this model. The number is #NUMBER parameters.",
      /(?<=[ ._-])(?<![\d.])([\d.]+)[ ._-]?([KMBTQ])(?=[ ._-])/i  => "#NUMBER total parameters in this model. The number is #NUMBER parameters.",
    },
    :sparse_count => {
      /(?<=[ ._-])A([\d.]+)[ ._-]?([KMBTQ])(?=[ ._-])/i => "#NUMBER parameters actively processed at any given time during inference. The number is #NUMBER parameters.",
    },
    :training_stage => {
      /(?<=[ ._-])PT(?=[ ._-])/i => "This is a model pre-trained only on a vast corpus of unstructured data.",
      /(?<=[ ._-])IT(?=[ ._-])/i => "This is a model instruct-tuned on structured data."
    },
    :vision => {
      /(?<=[ ._-])VL?(?=[ ._-])/i => "This filename may suggest this model can see visually if a multimodal sidecar \"mmproj\" file is loaded alongside.",
    },
    :storage_struct => {
      /(?<=[ ._-])IQ(\d+)(?=[ ._-])/i                     => "I-Quant, not to be conflated with Importance Matrix (I-Matrix) or Integer quants",
      /(?<=[ ._-])Q(\d+)\D(\d+)\D(\d+)\D(\d+)(?=[ ._-])/i => "Ancient",
      /(?<=[ ._-])Q(\d+)\D(\d+)(?=[ ._-])/i               => "Uniform",
      /(?<=[ ._-])KQ(\d+)(?=[ ._-])/i                     => "K-Quant",
      /(?<=[ ._-])Q(\d+)[ ._-]K(?=[ ._-])/i               => "K-Quant",
      /(?<=[ ._-])BF(\d+)(?=[ ._-])/i                     => "Brain Float",
      /(?<=[ ._-])F(\d+)(?=[ ._-])/i                      => "Float",
      /(?<=[ ._-])MXFP(\d+)(?=[ ._-])/i                   => "Microscaling Floating-Point",
      /(?<=[ ._-])FP(\d+)(?=[ ._-])/i                     => "Float",
      /(?<=[ ._-])I(\d+)(?=[ ._-])/i                      => "Integer",
      /(?<=[ ._-])T(\d+)(?=[ ._-])/i                      => "Ternary",
    },
    # # Compression distribution.
    # /\b(?:_\d)+\b/i            => "Uniform distribution of weights compression.",
    :subvariant_size => {
      /#{SUBVARIANT_SIZE_PREFIX}([ ._-]XXS)(?=[ ._-])/i => "A doubly-extra-small subvariant at this bits-per-weight level.",
      /#{SUBVARIANT_SIZE_PREFIX}([ ._-]XS)(?=[ ._-])/i  => "An extra-small subvariant at this bits-per-weight level.",
      /#{SUBVARIANT_SIZE_PREFIX}([ ._-]S)(?=[ ._-])/i   => "A small subvariant at this bits-per-weight level.",
      /#{SUBVARIANT_SIZE_PREFIX}([ ._-]M)(?=[ ._-])/i   => "A medium subvariant at this bits-per-weight level.",
      /#{SUBVARIANT_SIZE_PREFIX}([ ._-]L)(?=[ ._-])/i   => "A large subvariant at this bits-per-weight level.",
      /#{SUBVARIANT_SIZE_PREFIX}([ ._-]XL)(?=[ ._-])/i  => "An extra-large subvariant at this bits-per-weight level.",
      /#{SUBVARIANT_SIZE_PREFIX}([ ._-]XXL)(?=[ ._-])/i => "A doubly-extra-large subvariant at this bits-per-weight level.",
    },
    :distribution => {
      /(?<=[ ._-])i1(?=[ ._-])/i => "Weights compression fidelity distributed according to importance matrix calibration using mradermacher dataset.",
      /(?<=[ ._-])UD(?=[ ._-])/i => "Weights compression fidelity distributed according to importance matrix calibration using Unsloth dataset.",
    },
    :shard => {
      /(?<=[ ._-])(\d{5})\Dof\D(\d{5})(?=[ ._-])/i => "This is shard #IDENTITY_NUMBER of #BOUND_NUMBER. The numbers are #IDENTITY_NUMBER of #BOUND_NUMBER.",
    }
  }
  
  def self.decode_filename(raw_filename : String) : String
    filename = raw_filename.ensure_prefix(' ')
    stream = IO::Memory.new
    stream.puts "Model producer section."
    
    PATTERNS[:sidecar].each do |pattern, description|
      if match_data = filename.match pattern
        stream.puts "  This is a sidecar file meant to be used in addition to the main model file.",
             "    #{match_data[0]} : #{description}"
        break
      end
    end
    
    PATTERNS[:training_stage].each do |pattern, description|
      if match_data = filename.match pattern
        stream.puts "  Instruct-based post-training narrows a model's capability to reliably perform in structured chat or agentic context.",
             "    #{match_data[0]} : #{description}"
        break
      end
    end
    
    PATTERNS[:vision].each do |pattern, description|
      if match_data = filename.match pattern
        stream.puts "  Some models support multimodality or even so-called \"omnimodality\" to perceive non-textual media when loaded with a multimodal projector.",
             "    #{match_data[0]} : #{description}"
        break
      end
    end
    
    PATTERNS[:total_count].each do |pattern, description_template|
      if match_data = filename.match pattern
        number_text = "#{match_data[1]} #{SI_POSTFIX[match_data[2][0].upcase]}"
        description = description_template.gsub("#NUMBER", number_text)
        stream.puts "  The notional size of the model before quantization reflects capability, disk storage and memory requirements.",
             "    #{match_data[0]} : #{description}"
        break
      end
    end
    
    sparse? : Bool = false
    
    PATTERNS[:sparse_count].each do |pattern, description_template|
      if match_data = filename.match pattern
        sparse? = true
        number_text = "#{match_data[1]} #{SI_POSTFIX[match_data[2][0].upcase]}"
        description = description_template.gsub("#NUMBER", number_text)
        stream.puts "  This is a sparse Mixture of Experts model. Only a subset of its parameters require computational effort.",
             "    #{match_data[0]} : #{description}"
        break
      end
    end
    
    stream.puts "This is a dense monolith model. All of its parameters require computational effort" unless sparse?
    
    stream.puts "GGUF quantizer section."
    
    PATTERNS[:storage_struct].each do |pattern, structure|
      if match_data = filename.match pattern
        number_text = match_data[1]
        stream.puts "  Quantized model weights may be represented with different numerical structures in memory.",
             "    #{match_data[0]} : The algorithm and memory structure used in this file is #{structure}.",
             "  The number of bits allocated per each weight defines fidelity preserved in quantizing this model file.",
             "    #{match_data[0]} : The first number suggests that most of the weights in this model are encoded with #{number_text} BPW (bits per weight). The number is #{number_text} BPW."
        break
      end
    end
    
    PATTERNS[:subvariant_size].each do |pattern, description|
      if match_data = filename.match pattern
        stream.puts "  Within each level of overall quantization, there is slack for subvariants to be slightly larger or smaller.",
             "    #{match_data[1]} : #{description}"
        break
      end
    end
    
    PATTERNS[:distribution].each do |pattern, description|
      if match_data = filename.match pattern
        stream.puts "  Distribution of relative fidelity among weights may further be prioritized towards ones prevalent in a given dataset.",
             "    #{match_data[0]} : #{description}"
        break
      end
    end
    
    PATTERNS[:shard].each do |pattern, description_template|
      if match_data = filename.match pattern
        identity_number = match_data[1].lstrip '0'
        identity_number = "0" if identity_number.empty? # Leniently off-spec.
        bound_number = match_data[2].lstrip '0'
        description = description_template.gsub("#IDENTITY_NUMBER", identity_number).gsub("#BOUND_NUMBER", bound_number)
        stream.puts "  Very large files may be split into parts called \"shards.\"",
             "    #{match_data[0]} : #{description}"
        break
      end
    end
    
    return stream.to_s
  end
end

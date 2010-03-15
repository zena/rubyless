module RubyLess
  module SafeClass
    @@_safe_methods         ||= {} # defined for each class
    @@_safe_methods_parsed  ||= {} # full list with inherited attributes
    @@_safe_literal_classes ||= {}

    # List of safe methods for a specific class.
    def self.safe_methods_for(klass)
      # Caching safe_methods_all is bad when modules are dynamically added / removed.
      @@_safe_methods_parsed[klass] ||= build_safe_methods_list(klass)
    end

    # Return method type (options) if the given signature is a safe method for the class.
    def self.safe_method_type_for(klass, signature)
      # Signature might be ['name', {:mode => String, :type => Number}].
      # build signature arguments

      # Replace all hashes in signature by Hash class and check for arguments
      signature_args = []
      signature = signature.map do |s|
        if s.kind_of?(Hash)
          signature_args << s
          Hash
        else
          signature_args << nil
          s
        end
      end
      # Find safe method in all ancestry
      klass.ancestors.each do |ancestor|
        return nil if ancestor == RubyLess::SafeClass
        if type = safe_method_with_hash_args(ancestor, signature, signature_args)
          return type
        end
      end
      nil
    end

    def self.literal_class_for(klass)
      @@_safe_literal_classes[klass]
    end

    def self.safe_literal_class(hash)
      @@_safe_literal_classes.merge!(hash)
    end

    # Declare a safe method for a given class ( same as #safe_method)
    def self.safe_method_for(klass, methods_hash)
      defaults = methods_hash.delete(:defaults) || {}

      list = (@@_safe_methods[klass] ||= {})
      methods_hash.each do |k,v|
        k, hash_args = build_signature(k)
        v = {:class => v} unless v.kind_of?(Hash)
        v = defaults.merge(v)
        v[:method] = v[:method] ? v[:method].to_s : k.first.to_s
        v[:hash_args] = hash_args if hash_args
        list[k] = v
      end
    end

    def self.included(base)
      base.class_eval do

        # Declare safe methods. By providing
        #
        # The methods hash has the following format:
        #  signature => return type
        # or
        #  signature => options
        # or
        #  signature => lambda {|h| ... }
        #
        # The lambda expression will be called with @helper as argument during compilation.
        #
        # The signature can be either a single symbol or an array containing the method name and type arguments like:
        #  [:strftime, Time, String]
        #
        # If your method accepts variable arguments through a Hash, you should declare it with:
        #  [:img, String, {:mode => String, :max_size => Number}]
        #
        # Make sure your literal values are of the right type: +:mode+ and +'mode'+ are not the same here.
        #
        # If the signature is :defaults, the options defined are used as defaults for the other elements defined in the
        # same call.
        #
        # The return type can be a string with the class name or a class.
        #
        # Options are:
        # :class  the return type (class name)
        # :nil    set this to true if the method could return nil
        def self.safe_method(methods_hash)
          RubyLess::SafeClass.safe_method_for(self, methods_hash)
        end

        # A safe context is simply a safe method that can return nil in some situations. The rest of the
        # syntax is the same as #safe_method. We call it a safe context because it enables syntaxes such
        # as: if var = my_context(...) ---> enter context.
        def self.safe_context(methods_hash)
          methods_hash[:defaults] ||= {}
          methods_hash[:defaults][:nil] = true
          safe_method(methods_hash)
        end

        def self.safe_literal_class(hash)
          RubyLess::SafeClass.safe_literal_class(hash)
        end

        # Declare a safe method to access a list of attributes.
        # This method should only be used when the class is linked with a database table and provides
        # proper introspection to detect types and the possibility of NULL values.
        def self.safe_attribute(*attributes)
          attributes.each do |att|
            if col = columns_hash[att.to_s]
              opts = {}
              opts[:nil]   = col.default.nil?
              if col.number?
                opts[:class] = Number
              elsif col.text?
                opts[:class] = String
              else
                opts[:class] = col.klass
              end
              safe_method att.to_sym => opts
            else
              puts "Warning: could not declare safe_attribute '#{att}' (No column with this name found in class #{self})"
            end
          end
        end

        # Declare a safe method to access a list of properties.
        # This method should only be used in conjunction with the Property gem.
        def self.safe_property(*properties)
          columns = schema.columns
          properties.each do |att|
            if col = columns[att.to_s]
              opts = {}
              opts[:nil]   = col.default.nil?
              if col.number?
                opts[:class] = Number
              elsif col.text?
                opts[:class] = String
              else
                opts[:class] = col.klass
              end
              opts[:method] = "prop['#{att.to_s.gsub("'",'')}']"
              safe_method att.to_sym => opts
            else
              puts "Warning: could not declare safe_property '#{att}' (No property column with this name found in class #{self})"
            end
          end
        end


        # Declare a safe method for a given class
        def self.safe_method_for(klass, signature)
          SafeClass.safe_method_for(klass, signature)
        end

        # Hash of all safe methods defined for the class.
        def self.safe_methods
          SafeClass.safe_methods_for(self)
        end

        # Return the type if the given signature corresponds to a safe method for the class.
        def self.safe_method_type(signature)
          SafeClass.safe_method_type_for(self, signature)
        end

        # Return true if the class is safe (we can call safe_read on its instances)
        def self.safe_class?
          true
        end

        # Use this if you want to disable 'safe_read'. This is useful if you provided
        # a mock as return type signature.
        def self.disable_safe_read
          undef_method(:safe_read)
        end
      end  # base.class_eval
    end  # included


    # Return the type if the given signature corresponds to a safe method for the object's class.
    def safe_method_type(signature)
      if type = SafeClass.safe_method_type_for(self.class, signature)
        type[:class].kind_of?(Symbol) ? self.send(type[:class], signature) : type
      end
    end

    # Safe attribute reader used when 'safe_readable?' could not be called because the class
    # is not known during compile time.
    def safe_read(key)
      return "'#{key}' not readable" unless type = self.class.safe_method_type([key])
      self.send(type[:method])
    end

    private
      def self.build_signature(key)
        keys = key.kind_of?(Array) ? key : [key]
        keys[0] = keys[0].to_s
        hash_args = []
        signature = keys.map do |k|
          if k.kind_of?(Hash)
            hash_args << k
            Hash
          else
            hash_args << nil
            k
          end
        end
        [signature, (hash_args.compact.empty? ? nil : hash_args)]
      end

      def self.build_safe_methods_list(klass)
        list = {}
        (@@_safe_methods[klass] || {}).map do |signature, return_value|
          if return_value.kind_of?(Hash)
            return_value[:class] = parse_class(return_value[:class])
          elsif return_value.kind_of?(Proc) || return_value.kind_of?(Symbol)
            # keep
          else
            return_value = {:class => return_value}
          end
          method = signature.shift
          signature = [method] + signature.map {|e| parse_class(e)}
          list[signature] = return_value.freeze
        end
        list
      end

      def self.parse_class(klass)
        if klass.kind_of?(Array)
          if klass[0].kind_of?(String)
            [Module::const_get(klass[0])]
          else
            klass
          end
        else
          if klass.kind_of?(String)
            Module::const_get(klass)
          else
            klass
          end
        end
      end

      def self.safe_method_with_hash_args(klass, signature, hash_args)
        if type = safe_methods_for(klass)[signature]
          unless allowed_args = type[:hash_args]
            # All arguments allowed
            return type
          end

          # Verify arguments
          hash_args.each_with_index do |args, i|
            next unless args
            # verify for each position: ({:a => 3}, {:x => :y})
            return nil unless allowed_args_for_position = allowed_args[i]
            args.each do |k,v|
              return nil unless allowed_args_for_position[k] == v
            end
          end
          type
        else
          nil
        end
      end
  end
end

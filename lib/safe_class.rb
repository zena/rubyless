module RubyLess
  module SafeClass
    @@_safe_methods     ||= {} # defined for each class
    @@_safe_methods_all ||= {} # full list with inherited attributes
    
    # List of safe methods for a specific class.
    def self.safe_methods_for(klass)
      @@_safe_methods_all[klass] ||= build_safe_methods_list(klass)
    end
    
    # Return method type (options) if the given signature is a safe method for the class.
    def self.safe_method_type_for(klass, signature)
      if res = safe_methods_for(klass)[signature]
        res.dup
      else
        nil
      end
    end
    
    # Declare a safe method for a given class
    def self.safe_method_for(klass, hash)
      list = (@@_safe_methods[klass] ||= {})
      hash.each do |k,v|
        k = [k] unless k.kind_of?(Array)
        v = {:class => v} unless v.kind_of?(Hash) || v.kind_of?(Proc)
        list[k] = v
      end
    end
    
    def self.included(base)
      base.class_eval do
        
        # Declare a safe method through a hash of either
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
        # The return type can be a string with the class name or a class.
        #
        # Options are:
        # :class  the return type (class name)
        # :nil    set this to true if the method could return nil
        def self.safe_method(hash)
          list = (@@_safe_methods[self] ||= {})
          hash.each do |k,v|
            k = [k] unless k.kind_of?(Array)
            v = {:class => v} unless v.kind_of?(Hash) || v.kind_of?(Proc)
            list[k] = v
          end
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
                opts[:class] = RubyLess::Number
              elsif col.text?
                opts[:class] = String
              elsif att.to_s =~ /_at$/
                opts[:class] = Time
              else
                raise "Could not declare safe_method for '#{att}': could not guess return type"
              end
              safe_method att.to_sym => opts
            else
              puts "Warning: could not declare safe_attribute '#{att}' (No column with this name found in class #{self})"
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
        
        # Return true if the given signature corresponds to a safe method for the class.
        def self.safe_method_type(signature)
          if res = SafeClass.safe_method_type_for(self, signature)
            res.dup
          else
            nil
          end
        end
        
        # Return the method type (options) if the given signature is a safe method for the class.
        def safe_method_type(signature)
          self.class.safe_method_type(signature)
        end
      end  # base.class_eval
    end  # included
  
    private   
      def self.build_safe_methods_list(klass)
        list = klass.superclass.respond_to?(:safe_methods) ? klass.superclass.safe_methods : {}
        (@@_safe_methods[klass] || {}).map do |signature, return_value|
          if return_value.kind_of?(Hash)
            return_value[:class] = parse_class(return_value[:class])
          elsif !return_value.kind_of?(Proc)
            return_value = {:class => return_value}
          end
          signature.map! {|e| parse_class(e)}
          list[signature] = return_value
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
  end
end

module RubyLess
  module SafeClass
    def self.included(base)
      # add all methods from the module "AddActsAsMethod" to the 'base' module
      base.class_eval <<-END
        @@_safe_methods     ||= {} # defined for each class
        @@_safe_methods_all ||= {} # full list with inherited attributes

        def self.safe_method(hash)
          list = (@@_safe_methods[self] ||= {})
          hash.each do |k,v|
            k = [k] unless k.kind_of?(Array)
            v = {:class => v} unless v.kind_of?(Hash) || v.kind_of?(Proc)
            list[k] = v
          end
        end

        def self.safe_methods
          safe_methods_for(self)
        end
        
        def self.safe_methods_for(klass)
          @@_safe_methods_all[klass] ||= build_safe_methods_list(klass)
        end
        
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
        
        def self.safe_method?(signature)
          if res = safe_methods[signature]
            res.dup
          else
            nil
          end
        end
        
        def self.safe_method_for?(klass, signature)
          if res = safe_methods_for(klass)[signature]
            res.dup
          else
            nil
          end
        end
        
        def safe_method?(signature)
          self.class.safe_methods[signature]
        end
        
        def self.safe_method_for(klass, hash)
          list = (@@_safe_methods[klass] ||= {})
          hash.each do |k,v|
            k = [k] unless k.kind_of?(Array)
            v = {:class => v} unless v.kind_of?(Hash) || v.kind_of?(Proc)
            list[k] = v
          end
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

        def self.safe_attribute?(sym)
          column_names.include?(sym) || zafu_readable?(sym) || safe_attribute_list.include?(sym.to_s)
        end

        def self.zafu_readable?(sym)
          if sym.to_s =~ /(.*)_zips?$/
            return true if self.ancestors.include?(Node) && RelationProxy.find_by_role($1.singularize)
          end
          self.zafu_readable_attributes.include?(sym.to_s)
        end
      END
    end
  end
end

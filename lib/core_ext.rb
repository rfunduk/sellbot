class Object
  def recursively_symbolize_keys
    self
  end
end

class Array
  def recursively_symbolize_keys
    map(&:recursively_symbolize_keys)
  end
end

class Hash
  def recursively_symbolize_keys
    inject({}) do |acc, (k,v)|
      acc[k.to_sym] = v.recursively_symbolize_keys
      acc
    end
  end
end

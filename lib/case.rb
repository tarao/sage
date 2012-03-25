class String
  def to_camel()
    return split('_').map(&:capitalize).join
  end

  def to_snake()
    return split(/(?=[A-Z])/).map(&:downcase).join('_')
  end
end

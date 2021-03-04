class Xanitize

  def self.clean(target)
    # options always has items to the effect of translate <div> elements and contained good to just a newline char
    #   and that style attributes get removed
    target.gsub!(/<div>(.+?)<\/div>/i, '\1' + "\n")
    target.gsub!(/<.+?>/i,'')
    return target.gsub('&nbsp;', ' ')
  end
end
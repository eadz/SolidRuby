#    This file is part of SolidRuby.
#
#    SolidRuby is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    SolidRuby is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with SolidRuby.  If not, see <http://www.gnu.org/licenses/>fre.

$fn = 64
require 'cgi'

module SolidRuby
  include SolidRuby::BillOfMaterial
  include SolidRuby::ScrewThreads
  include SolidRuby::PrintedThreads
  include SolidRuby::Extras
  include SolidRuby::Helpers
  include SolidRuby::Primitives
  include SolidRuby::CSGModelling
  include SolidRuby::CSGModifiers
  include SolidRuby::Assemblies
  include SolidRuby::Transformations
  include SolidRuby::Parameters
  include Math

  def get_position_rec(obj, level = 0)
    position = [0, 0, 0]
    return position if obj.nil?
    obj.each do |o|
      o.transformations.each do |t|
        next unless t.class == Translate
        t.args[:x] ||= 0
        t.args[:y] ||= 0
        t.args[:z] ||= 0
        position[0] += t.args[:x]
        position[1] += t.args[:y]
        position[2] += t.args[:z]
      end
      #		puts "  " * level + position.inspect
      x, y, z = get_position_rec(o.children, level + 1)
      position[0] += x
      position[1] += y
      position[2] += z
    end
    position
  end

  #	this is experimental, does only work on simple parts. example:
  # The bolt head is on the -z plane, this will move it to "zero"
  def position(obj)
    get_position_rec(obj.children)
  end

  # produces a hull() of 2 cylidners
  # accepts d,r,h for cylinder options
  # l long slot length
  def long_slot(args)
    hull(cylinder(d: args[:d], r: args[:r], h: args[:h]), cylinder(d: args[:d], r: args[:r], h: args[:h]).translate(x: args[:l]))
  end

  def radians(a)
    a / 180.0 * Math::PI
  end

  def degrees(a)
    a * 180 / Math::PI
  end

  def save!(extra)
    Dir.glob('lib/**/*.rb').map { |l| get_classes_from_file(l) }.flatten.map { |l| save_all(l, extra) }
  end

  # Saves all files generated of a SolidRuby file
  # Saves outputs of
  # - show
  # - output
  # - view*
  def save_all(class_name, extra)
    res = class_name.send :new

    # skip defined classes
    skip = class_name.send :get_skip
    skip = [] if skip.nil?
    skip << 'show_hardware'
    added_views = class_name.send :get_views

    # regexp for output* view* show*
    (res.methods.grep(Regexp.union(/^output/, /^view/, /^show/)) + added_views).each do |i|
      next if skip.include? i.to_s
      output = nil

      begin
        res.send :initialize # ensure default values are loaded at each interation
        output = res.send i

        # if previous call resulted in a SolidRubyObject, don't call the show method again,
        # otherwise call it.
        unless	output.is_a? SolidRubyObject
          output = if i.to_s.include? 'output'
                    res.output
                  else
                    res.show
                  end
        end

        output.save("output/#{res.class}_#{i}.scad", "$fn=#{fn};") unless output.nil?
      rescue Exception => e
        File.open("output/#{res.class}_#{i}.scad", "w") do |file|
          file <<
            <<~ERROR
               echo("--ERROR: #{e.message}");
               echo("#{::CGI.escapeHTML(e.backtrace.last)}");
               assert(false); // force stop rendering
               /*
               Full stack trace:
               #{e.backtrace.join("\n")}
               */
            ERROR
        end
      end
    end
  end

  def get_classes_from_file(filename)
    classes = []
    File.readlines(filename).find_all { |l| l.include?('class') }.each do |line|
      # strip all spaces, tabs
      line.strip!
      # ignore comments (Warning: will not worth with ruby multi line comments)
      next if line[0..0] == '#'
      #	strip class definition
      line = line[6..-1]
      # strip until space appears - or if not, to the end
      classes << Object.const_get(line[0..line.index(' ').to_i - 1])
    end

    classes
  end
end

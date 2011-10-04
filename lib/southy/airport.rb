require 'csv'

class Southy::Airport

  @@timezones = {
          '-10' => 'Pacific/Honolulu',
          '-9'  => 'America/Juneau',
          '-8'  => 'America/Los_Angeles',
          '-7'  => 'America/Denver',
          '-6'  => 'America/Chicago',
          '-5'  => 'America/New_York'
  }
  @@airports = {}

  attr_accessor :name, :code, :tz_offset

  def self.dump
    Southy::Airport.load_airports if @@airports.empty?

    @@airports.each do |code, airport|
      puts "#{code} -> #{airport}"
    end
  end

  def self.lookup(code)
    Southy::Airport.load_airports if @@airports.empty?

    @@airports[code]
  end

  def timezone
    @@timezones[tz_offset] or raise "Unknown timezone offset: #{self}"
  end

  def to_s
    "#{name} (#{code}) - #{tz_offset}"
  end

  private

  def self.load_airports
    datafile = File.dirname(__FILE__) + "/us-airports.dat"
    File.open(datafile, 'r') do |file|
      file.readlines.each do |line|
        pieces = line.parse_csv
        if pieces[3] == 'United States'
          airport = Southy::Airport.new
          airport.name = pieces[1]
          airport.code = pieces[4]
          airport.tz_offset = pieces[9]
          @@airports[airport.code] = airport
        end
      end
    end
  end

end


class Southy::Timezones
  LOOKUP =
          {
                  'DEN' => 'America/Denver',
                  'HOU' => 'America/Chicago',
                  'LAX' => 'America/Los_Angeles',
                  'MSY' => 'America/Chicago',
                  'SFO' => 'America/Los_Angeles'
          }

  def self.lookup(code)
    LOOKUP[code]
  end
end

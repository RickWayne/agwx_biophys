require "test/unit"
require "agwx_biophys"
require "agwx_grids"

class TestAgwxBiophys < Test::Unit::TestCase
  include AgwxBiophys::DegreeDays
  include AgwxGrids
  
  def setup
    @min_grid = Grid.new(File.join(File.dirname(__FILE__),'grids','WIMNTMin2012'),Grid::DAILY)
    @max_grid = Grid.new(File.join(File.dirname(__FILE__),'grids','WIMNTMax2012'),Grid::DAILY)
  end
  
  def test_rect_DD
    assert_equal(18, rect_DD(50,86))
    assert_equal(27, rect_DD(50,86,41))
  end
  
  def test_sine_DD
    assert(sine_DD(10,20), "Could not even call sine_DD")
  end
  
  def test_sine_is_less_than_ModB
    [[10,25],[20,35],[40,60],[41,60],[42,60],[45,60],[50,86],[50,90],[51,90],[55,90],[60,90]].each do |(lower,upper)|
      sine = sine_DD(lower,upper)
      modB = modB_DD(lower,upper)
      diff =  modB - sine
      assert(diff >= 0) if (modB > 0 || sine > 0)
    end
  end
  
  def get_temps_for(longitude = -95.6, latitude = 43.90)
    max_grid = Grid.new(File.join(File.dirname(__FILE__),'grids','WIMNTMax2012'),Grid::DAILY)
    min_grid = Grid.new(File.join(File.dirname(__FILE__),'grids','WIMNTMin2012'),Grid::DAILY)
    mins = min_grid.at_by_long_lat(longitude,latitude).inject({}) {|hash,(doy,val)| hash.merge({doy => to_fahrenheit(val)}) }
    maxes = max_grid.at_by_long_lat(longitude,latitude).inject({}) {|hash,(doy,val)| hash.merge({doy => to_fahrenheit(val)}) }
    [mins,maxes]
    
  end
  
  def test_get_temps_for
    mins,maxes = get_temps_for
    assert_equal(Hash,mins.class)
    assert_equal(Hash, maxes.class)
    assert_equal(to_fahrenheit(-7.53),mins[1])
    assert_equal(to_fahrenheit(21.20), mins[170]) # this does appear to be 21.20 in the grid file...???
    assert_equal(to_fahrenheit(32.06), maxes[170])
    assert_equal(366, mins.keys.size)
    mins.keys.sort.each { |doy| assert mins[doy] < maxes[doy] }
  end
  
  def test_rect_one_day
    mins,maxes = get_temps_for
    assert_equal(to_fahrenheit(21.20), mins[170]) # this does appear to be 21.20 in the grid file...???
    assert_equal(to_fahrenheit(32.06), maxes[170])
    assert_in_delta(29.934, rect_DD(mins[170],maxes[170]),0.00001)
    assert_in_delta(0.0, rect_DD(mins[71],maxes[71],50), 2 ** -20)
  end
  
  def test_rect_sequence
    mins,maxes = get_temps_for
    # loads up andi_dds as a hash of doy => getstndd value
    andi_dds = eval(File.open(File.join(File.dirname(__FILE__),'rect_dd_seq_2012.rb')).read)
    doys = andi_dds.keys.sort
    (doys.first..doys.last).each { |doy| assert_equal(ANDI_DDS[doy], rect_DD(mins[doy],maxes[doy],50).round) }
  end
  
  def test_sine_one_day
    mins,maxes = get_temps_for
    assert_in_delta(17.3, sine_DD(mins[170],maxes[170],50,86),0.001)
  end
  
  def test_cumulate_rect
    mins,maxes = get_temps_for
    expected = {50 => 0, 100 => 142, 150 => 549, 170 => 898, 230 => 2320, 270 => 2919}
    expected.each do |doy,dd|
      cumulated,days_found = cumulate(mins,maxes,1,doy,50) {|min,max,base,upper| rect_DD(min,max,base).round}
      assert_equal(doy, days_found,"Wrong number of days found in data")
      assert_in_delta(dd, cumulated,cumulated * 0.006,"Wrong DD values for DOY #{doy}")
    end
  end
  
  def test_cumulate_sine
    mins,maxes = get_temps_for
    # for doy in $DOYS; do echo "$doy => `getstndd 2012 1 $doy Sine 50 WIMN $LATLONG`,"; done
    expected = {50 => 2, 100 => 203, 150 => 619, 170 => 937, 230 => 2039, 270 => 2562}
    expected.each do |doy,dd|
      cumulated,days_found = cumulate(mins,maxes,1,doy,50) {|min,max,base,upper| sine_DD(min,max,base).round}
      assert_equal(doy, days_found,"Wrong number of days found in data")
      assert_in_delta(dd, cumulated,cumulated * 0.007,"Wrong DD values for DOY #{doy}")
    end
  end
  
  def test_cumulate_modb
    mins,maxes = get_temps_for
    # for doy in $DOYS; do echo "$doy => `getstndd 2012 1 $doy Sine 50 WIMN $LATLONG`,"; done
    expected = { 50 => 4, 100 => 254, 150 => 723, 170 => 1077, 230 => 2449, 270 => 3085 }
    expected.each do |doy,dd|
      cumulated,days_found = cumulate(mins,maxes,1,doy,50) {|min,max,base,upper| modB_DD(min,max,base,upper).round}
      assert_equal(doy, days_found,"Wrong number of days found in data")
      assert_in_delta(dd, cumulated,cumulated * 0.006,"Wrong DD values for DOY #{doy}")
    end
  end
  
end
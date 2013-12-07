require "test/unit"
require "agwx_biophys"
require "agwx_grids"

class TestAgwxBiophys < Test::Unit::TestCase
  include AgwxBiophys::DegreeDays
  include AgwxGrids
  def test_rect_DD
    assert_equal(10, rect_DD(10,30))
    assert_equal(10, rect_DD(10,40)) # Should be the same, since the default cuts off at 30
    assert_equal(15, rect_DD(10,30,5,35))
  end
  
  def test_sine_DD
    assert(sine_DD(10,20), "Could not even call sine_DD")
  end
  
  def get_temps_for(longitude = -95.6, latitude = 43.90)
    max_grid = Grid.new(File.join(File.dirname(__FILE__),'grids','WIMNTMax2012'),Grid::DAILY)
    min_grid = Grid.new(File.join(File.dirname(__FILE__),'grids','WIMNTMin2012'),Grid::DAILY)
    maxes = max_grid.at_by_long_lat(longitude,latitude)
    max_arr = maxes.keys.sort.collect { |doy| maxes[doy] }
    mins = min_grid.at_by_long_lat(longitude,latitude)
    min_arr = mins.keys.sort.collect { |doy| mins[doy] }
    [min_arr,max_arr]
  end
  
  def test_get_temps_for
    mins,maxes = get_temps_for
    assert_equal(-6.98,mins[0])
    (0..mins.size-1).each { |ii| assert mins[ii] < maxes[ii] }
  end
end
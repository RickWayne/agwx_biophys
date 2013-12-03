require 'test/unit'
require 'agwx_biophys'

class TestET < Test::Unit::TestCase
  include AgwxBiophys::ET
  def test_rad_lat
    [
      [0,0],
      [30,0.5235983333],
      [45,0.7853975],
      [60,1.0471966667],
      [90,1.570795],
      [180,3.14159]
    ].each do |lat,radians|
      assert_in_delta(radians, rad_lat(lat), 0.00001)
    end
    assert_equal(0, rad_lat(0.0))
    assert_equal(Math::PI, rad_lat(180.0))
    assert_equal(Math::PI/2.0, rad_lat(90.0))
  end
  
  def test_daily_to_sol
    assert_equal(0.0864, daily_to_sol(1.0))
  end
  
  def test_declin
    [
      [1,-0.4019921553],
      [150,0.3809480272],
      [172,0.41],
      [200,0.3632890322],
      [250,0.092707884]
    ].each do |doy,declination|
      assert_in_delta(declination, declin(doy), 2 ** -20)
    end
  end
  
  def test_sunrise_angle
    [
      [1,0,1.5707963268],
      [150,30,1.8041439502],
      [172,45,2.020424427],
      [200,60,2.2895663737],
      [1,60,0.7431090864],
      [150,45,1.9828717405],
      [172,30,1.8244415261],
      [200,0,1.5707963268]
      
    ].each do |doy,latitude,sun_angle|
      assert_in_delta(sun_angle, sunrise_angle(doy,latitude), 0.00001)
    end
  end
  
  def test_sunrise_hour
    [
      [1,0,5.999994932],
      [150,30,5.1086719137],
      [172,45,4.2825406486],
      [200,60,3.254493271]
    ].each do |doy,latitude,sun_hour|
      assert_in_delta(sun_hour, sunrise_hour(doy,latitude), 0.00001)
    end
  end

  def test_day_hours
    [
      [1,0,12.0],
      [150,30,13.7826561727],
      [172,45,15.4349187028],
      [200,60,17.491013458]
    ].each do |doy,latitude,day_hrs|
      assert_in_delta(day_hrs, day_hours(doy,latitude), 0.0001)
    end
  end
  def test_av_eir
    [
      [1,1414.8379112589],
      [150,1326.4494599268],
      [172,1319.9344503498],
      [200,1321.3095743309]
    ].each do |doy,aveir|
      assert_in_delta(aveir, av_eir(doy), 0.001)
    end
  end
  
  def test_to_eir
    [
      [1,0,35.8090258247],
      [150,30,40.7680366801],
      [172,45,41.8738275449],
      [200,60,38.3861488725]
    ].each do |doy,latitude,total_eir|
      assert_in_delta(total_eir, to_eir(doy,latitude), 0.001)
    end
  end
  
  def test_lwu
    [
      [273.15,293.15,450.406110886],
      [268.15,308.15,466.818655323],
      [293.15,313.15,518.7552592804]
    ].each do |min,max,exp_lwu|
      assert_in_delta(exp_lwu, lwu(min,max), 2 ** -20)
    end
  end
  
  def test_sfactor
    [
      [273.15,293.15,-6.144831995],
      [268.15,308.15,-6.464954995],
      [293.15,313.15,-7.467923995]
    ].each do |min,max,exp_sfactor|
      assert_in_delta(exp_sfactor, sfactor(min,max), 2 ** -20)
    end
  end
    
end
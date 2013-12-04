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
      assert_in_delta(day_hrs, day_hours(doy,latitude), 0.00002)
    end
  end
  def test_av_eir
    [
      [1,1414.8379112589],
      [150,1326.4494599268],
      [172,1319.9344503498],
      [200,1321.3095743309]
    ].each do |doy,aveir|
      assert_in_delta(aveir, av_eir(doy), 0.00006)
    end
  end
  
  def test_to_eir
    [
      [1,0,35.8090258247],
      [150,30,40.7680366801],
      [172,45,41.8737911],
      [200,60,38.3861488725]
    ].each do |doy,latitude,total_eir|
      assert_in_delta(total_eir, to_eir(doy,latitude), 0.00005)
    end
  end
  
  def test_to_clr
    [
      [1,0,28.7069041338],
      [150,30,32.9899653948],
      [172,45,34.1124418882],
      [200,60,31.4758531933]
    ].each { |doy,lat,clr| assert_in_delta(clr, to_clr(doy,lat), 0.0003) }
  end
  
  def test_lwu
    [
      [5,15,30.2297320891],
      [16,24,34.73182695],
      [18,27,35.9318491504],
      [16,24,34.7318269495]
    ].each do |min,max,exp_lwu|
      assert_in_delta(exp_lwu, lwu(min,max), 0.000001)
    end
  end
  
  def test_sfactor
    [
      [5,15,0.5548],
      [16,24,0.6832],
      [18,27,0.7108625]
    ].each do |min,max,exp_sfactor|
      assert_in_delta(exp_sfactor, sfactor(min,max), 2 ** -20)
    end
  end
  
  def test_exponentiation
    assert_in_delta(2.71828182845904, Math.exp(1), 2 ** -20)
    assert_in_delta(148.4131591026, Math.exp(5), 2 ** -20)
    [
      [5 ,15,10  ,283.0, 0.9252419575,200.4076128756],
      [16,24,20  ,293.0, 0.7328604333,167.2440168899],
      [18,27,22.5,295.5, 0.6747883114,160.1550057145]
    ].each do |min,max,avg,avg_kelvin,lo,hi|
      avg_temp = (min+max) / 2.0
      assert_in_delta(avg, avg_temp, 2 ** -20)
      assert_in_delta(avg_temp + 273.0, avg_kelvin, 2 ** -20)
      avg_kelvin = avg_temp + 273
      lo_exp = Math.exp(-0.000777*avg_temp*avg_temp)
      hi_exp = Math.exp( 1500.0/(273.0+avg_temp))
      assert_in_delta(hi, hi_exp, 2 ** -20)
      assert_in_delta(lo, lo_exp, 2 ** -20)
    end
  end
  
  def test_sky_emiss
    [
      [0.1,5,15     ,0.7585118491],
      [0.2,16,24    ,0.8087234269],
      [0.499,18,27  ,0.8238802507],
      [0.51,5,15    ,0.7608136901],
      [1,16,24      ,0.79951019],
      [2,18,27      ,0.8905844568],
      [1.0,16.0,24.0,0.79951019]
    ].each do |vp,min,max,sky|
      assert_in_delta(sky, sky_emiss(vp,min,max,(min+max)/2.0), 0.000001,"Out of range for vp #{vp} min #{min} max #{max}")
    end  
  end
  
  def test_angstrom
    [
      [0.1,5,15     ,0.2098834905],
      [0.2,16,24    ,0.1575797636],
      [0.499,18,27  ,0.1417914055],
      [0.51,5,15    ,0.2074857395],
      [1,16,24      ,0.1671768854],
      [2,18,27      ,0.0723078575],
      [1.0,16.0,24.0,0.16718]
    ].each { |vp,min,max,angs| assert_in_delta(angs, angstrom(vp,min,max,(min+max)/2.0), 0.000004) }
    
  end
  def test_clr_ratio
    [
      [62,1,0,0.186603194],
      [142,150,30,0.3718949036],
      [336,172,45,0.8510208708],
      [62,200,60,0.1701876028]
    ].each { |dAvSol,doy,lat,clr_ratio| assert_in_delta(clr_ratio, clr_ratio(dAvSol,doy,lat), 2 ** -20) }
  end
  
  def test_lwnet
    [
      [0.1,5,15,142,150,30         ,2.35957],
      [0.2,16,24,336,172,45        ,4.65767],
      [0.499,18,27,62,200,60       ,0.86708],
      [1.0,16.0,24.0,336.0,172,45.0,4.94133]
    ].each do |vp,min,max,sol,doy,lat,lwnet|
      assert_in_delta(lwnet, lwnet(vp,min,max,(min+max)/2.0,sol,doy,lat), 0.000025,"lwnet for #{vp}")
    end
  end

  def test_ets_with_obs
    # DAvSol,DMnTAir,DMxTAir,DAvTAir,DAvVPre,theDate,latitude,DRefET,DPctClr
  
    et_obs = [ 
      [336.0,16.0,24.0,20.0,1.0,'2013-06-21',45.0,0.24,85.10],
      [244.40,10.80,24.88,18.32,1.49,'2013-06-01',44.12,0.18,63.05],
      [285.40,5.23,15.91,10.60,0.86,'2013-06-02',44.12,0.17,73.49],
      [319.60,3.63,21.95,13.82,0.92,'2013-06-03',44.12,0.20,82.15],
      [45.76,9.95,13.56,11.41,1.25,'2013-06-04',44.12,0.03,11.74],
      [97.60,9.88,15.20,11.28,1.27,'2013-06-05',44.12,0.07,25.01],
      [62.95,9.55,13.01,11.00,1.26,'2013-06-06',44.12,0.04,16.10],
      [176.90,8.48,19.95,13.43,1.28,'2013-06-07',44.12,0.12,45.20],
      [131.80,9.21,19.31,14.57,1.35,'2013-06-08',44.12,0.09,33.63],
      [158.40,11.08,23.55,17.22,1.51,'2013-06-09',44.12,0.12,40.37],
      [234.00,14.20,26.73,20.02,1.78,'2013-06-10',44.12,0.19,59.58],
      [220.00,12.74,26.06,20.13,1.84,'2013-06-11',44.12,0.18,55.96],
      [142.00,13.74,25.72,18.78,1.86,'2013-06-12',44.12,0.12,36.09],
      [329.10,13.61,24.73,19.16,1.46,'2013-06-13',44.12,0.25,83.57],
      [336.40,11.01,24.85,18.69,1.34,'2013-06-14',44.12,0.24,85.37],
      [190.20,14.12,26.06,18.89,1.93,'2013-06-15',44.12,0.16,48.24],
      [349.00,13.27,27.64,20.92,1.52,'2013-06-16',44.12,0.27,88.48],
      [297.40,13.74,27.97,20.09,1.55,'2013-06-17',44.12,0.23,75.37],
      [345.90,9.55,22.27,15.83,1.14,'2013-06-18',44.12,0.24,87.64],
      [348.00,6.63,25.58,17.61,1.24,'2013-06-19',44.12,0.24,88.16],
      [331.50,14.34,29.81,22.59,1.52,'2013-06-20',44.12,0.26,83.98],
      [130.30,16.84,25.53,20.66,2.06,'2013-06-21',44.12,0.11,33.01],
      [134.30,18.37,25.59,20.98,2.23,'2013-06-22',44.12,0.12,34.03],
      [297.30,17.58,29.69,23.44,2.24,'2013-06-23',44.12,0.26,75.35],
      [198.10,19.17,28.10,22.58,2.27,'2013-06-24',44.12,0.18,50.23],
      [195.10,17.85,25.98,21.67,2.30,'2013-06-25',44.12,0.17,49.49],
      [235.70,20.29,28.08,23.26,2.37,'2013-06-26',44.12,0.22,59.82],
    ].each { |arr| arr[5] = Date.parse(arr[5]).yday }
      
    et_obs.each do |sol,min,max,avg,vapr,yday,lat,et,pct|
      # max_temp,min_temp,avg_v_press,d_to_sol,doy,lat
      ref_et,pct_clr = et(max,min,avg,vapr,sol,yday,lat)
      assert_in_delta(et, ref_et.round(2), 0.00001,"ET bludgered for #{Date.civil(2013,1,1)+yday-1}")
      assert_in_delta(pct, pct_clr.round(2), 0.00001,"PctClr bludgered for #{Date.civil(2013,1,1)+yday-1}")
    end
  end
end
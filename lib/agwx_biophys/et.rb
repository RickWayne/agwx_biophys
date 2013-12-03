module AgwxBiophys
  module ET
    SOLCON    = 1367.0
    STEFAN    = (0.0864*0.0000000567)
    SFCEMISS  = 0.96
    ALBEDO    = 0.25
    KELVIN    = 273.15
    
    def rad_lat(lat); lat * Math::PI / 180.0;end

    def daily_to_sol(total_sol); 0.0864 * total_sol; end

    def declin(doy)
      0.41 * 
        Math::cos(
          2 * Math::PI * ( doy - 172.0 ) / 365.0
        )
    end

    def sunrise_angle(doy,lat)
      Math.acos(
        -1 *
        Math.tan(declin(doy)) *
        Math.tan(rad_lat(lat))
      )
    end

    def sunrise_hour(doy,lat); 12 - ( 12 / Math::PI ) * sunrise_angle(doy,lat); end

    def day_hours(doy,lat); 24 - 2 * sunrise_hour(doy,lat); end

    def av_eir(doy)
      SOLCON * ( 1 + 0.035 * Math.cos( 2 * Math::PI * doy / 365.0 ) )
    end
    
    def to_eir(doy,lat)
      ( 0.0864 / Math::PI ) * av_eir(doy) *

      (
        sunrise_angle(doy,lat) *
         Math.sin( declin(doy) ) *
         Math.sin( rad_lat(lat) ) +
         
        Math.cos( declin(doy) ) *
         Math.cos( rad_lat(lat) ) *
         Math.sin( sunrise_angle(doy,lat) )
      )
    end
    
    def c_to_k(temperature); temperature + KELVIN; end

    # Remember, temps in kelvin!
    def lwu(min_temp,max_temp)
      avg = (min_temp+max_temp) / 2.0
      SFCEMISS * STEFAN * (273.15+avg) ** 4
    end
    
    def sfactor(min_temp,max_temp)
      avg = (min_temp+max_temp) / 2.0
      0.398 + 0.0171 * avg - 0.000142 * avg * avg
    end
    
    def sky_emiss(avg_v_press,min_temp,max_temp)
      avg_temp = (min_temp+max_temp) / 2.0
      if ( avg_v_press > 0.5)
        0.7 + (5.95e-4) * avg_v_press * Math.exp( 1500/(273+avg_temp) );
      else
        (1 - 0.261 * Math.exp(-0.000777 * avg * avg))
      end
    end
    
    # Here's the old Java code
    # double rad_lat =       lat *Math.PI/180.0;
    # double DailyToSol =    0.0864 * DToSol;
    # double Declin =    0.41 *Math.cos( 2 * Math.PI * ( dayOfYear -172. ) / 365. );
    # double Sunrise_Angle = Math.acos( -1*Math.tan(Declin) * Math.tan(rad_lat));
    # double Sunrise_Hour = 12 - ( 12 / Math.PI ) * Sunrise_Angle;
    # double Day_Hours = 24 - 2 * Sunrise_Hour;

    # double AvEIR = SOLCON * ( 1 + 0.035 * Math.cos( 2 * Math.PI * dayOfYear / 365. ) );
    # double ToEIR = ( 0.0864 / Math.PI ) * AvEIR *
    #     ( Sunrise_Angle * Math.sin( Declin ) * Math.sin( rad_lat )
    #     + Math.cos( Declin ) * Math.cos( rad_lat ) * Math.sin( Sunrise_Angle ) );
    #     /* MJ/SQM/DY */
    # 
    # double ToClr = ToEIR * (-.7 + 0.86*Day_Hours) / Day_Hours ;
    # 
    # double T = ( DMxTAir + DMnTAir ) / 2;
    # double LWU = SFCEMISS * STEFAN * Math.pow( 273.15+T,4  ); /*LONG WAVE RAD
    #                          EMITTED OUT */
    # double Sfactor = 0.398 + 0.0171 * T - 0.000142 * T * T;
    # 
    
    
  end
end
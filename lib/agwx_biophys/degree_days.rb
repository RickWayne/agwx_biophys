module AgwxBiophys
  module DegreeDays

    # return an array so that we can access arr[0..yDim][0..xDim]
    def cumulate_array(value=0.0)
      arr = Array.new(Y_DIM)
      for y in 0..MAX_Y_INDEX
        arr[y] = Array.new(X_DIM,value)
      end
      arr
    end

    # Calculate rect DD from min and max for this day. Everything is in Celsius.
    def rect_DD(min,max,base=10,upper=30)
      max = [upper,max].min
      min = [upper,min].min
      rect = ((max + min) / 2.0) - base
      # Never return a negative number
      rect >= 0.0 ? rect : 0.0
    end

    def rect_DD_from_avg(avg,base=10,upper=30)
      avg = [upper,avg].min
      rect = avg - base
      rect >= 0.0 ? rect : 0.0
    end

    def modB_DD(min,max,base=10,upper=30)
      min = [base,min].max
      max = [base,max].max
      rect_DD(min,max,base,upper)
    end

    DD_MAX_TEMP = 30
    M_1_PI =	0.31830988618379067154
    
    def sine_DD(min,max,base=10)
      alpha = nil
      o1 = o2 = nil
      dd = nil
      avg = (min + max) / 2.0
      #
      # Source Degree-Days: The Calculation and Use
      # of Heat Units in Pest management
      # Original returns an error if min > max
        #           if (TMin > TMax) {
        # RegErr("CalcDayDD:SineDD:","","Tmin > Tmax");
        # return -9999999;
      return DD_MAX_TEMP - base if (min >= DD_MAX_TEMP)
      return 0 if (max <= base)
      return avg - base if (max <= DD_MAX_TEMP && min >= base)

      alpha = (max-min)/2;
      if (max <= DD_MAX_TEMP && min < base)
        o1    = Math.asin( (base-avg)/alpha)
      	return M_1_PI*( (avg-base) * (Math::PI / 2-o1) + alpha*cos(o1) )
      end
      
      if (max >  DD_MAX_TEMP && min >= base)
        o2    = asin( (DD_MAX_TEMP-avg)/alpha);
      	return M_1_PI*( (avg-base) * (o2+M_1_PI) +
      		(DD_MAX_TEMP-base) * (Math::PI / 2-o2) - alpha*cos(o2) )
      end
      
      if (max >  DD_MAX_TEMP && min < base)
        o1    = asin( (base-avg)/alpha);
        o2    = asin( (DD_MAX_TEMP-avg)/alpha);
      	return M_1_PI*( (avg-base)*(o2-o1) + alpha*(cos(o1)-cos(o2))
      			+ (DD_MAX_TEMP-base)*(Math::PI / 2-o2) )
      end
    end
    
    def to_fahrenheit(celsius)
      (celsius * (9.0 / 5.0)) + 32.0
    end

    def frost?(grid,longi_index,lati_index,doy,frost_value)
      val = grid.get_by_index(longi_index,lati_index,doy)
      return false unless val
      return false unless val != grid.mD.badVal
      return (val <= frost_value)
    end

    # Find the date of first frost -- defined as the first day after July 1 with a min temp below 0 C --
    # for each grid point for each year. Return a hash keyed by year, of X by Y arrays of DOYs.
    def frost_doys(min_grids,start_year=START_YEAR,end_year=END_YEAR,frost_value=0.0)
      frost_doys = {}
      for year in (start_year..end_year)
        frost_doys[year] = cumulate_array(NO_DOY)
        # We start with 0 grid cells at frost (it's July, after all). When the number reaches
        # NUM_GRID_CELLS, we know we've seen frost everywhere on the grid and can safely
        # terminate the loop.
        num_frosty_grid_cells = 0
        # Can't use START_DOY or END_DOY here since frost might extend outside the growing season
        (START_OF_JULY..366).each do |doy|
          if min_grids[year].get_by_index(0,0,doy)
            for lati_index in (0..MAX_Y_INDEX)
              for longi_index in (0..MAX_X_INDEX)
                if frost_doys[year][lati_index][longi_index] == NO_DOY && frost?(min_grids[year],longi_index,lati_index,doy,frost_value)
                  frost_doys[year][lati_index][longi_index] = doy
                  num_frosty_grid_cells += 1
                  break if num_frosty_grid_cells >= NUM_GRID_CELLS
                end
                break if num_frosty_grid_cells >= NUM_GRID_CELLS
              end
            end
          end
        end
      end
      frost_doys
    end

    def cell_series(grid_hash,lati_index,longi_index)
      series = []
      grid_hash.keys.sort.each do |key|
        series << grid_hash[key][lati_index][longi_index]
      end
      series
    end

    def median(array)
      return nil unless array && array.size > 0 && (array = array.compact).size > 0
      sorted = array.sort
      len = sorted.length
      return (sorted[(len - 1) / 2] + sorted[len / 2]) / 2.0
    end

    def build_averages(min_grids,max_grids,start_year=START_YEAR,end_year=END_YEAR)
      averages = {}
      layers_for_doy = {}
      # print "building averages. "
      # check how many years have data for each doy
      (START_DOY..END_DOY).each do |doy|
        for year in (start_year..end_year)
          # Does this year have this DOY?
          if min_grids[year].get_by_index(0,0,doy)
            if layers_for_doy[doy]
              layers_for_doy[doy] += 1
            else
              layers_for_doy[doy] = 1
            end
          end
        end
      end
      (START_DOY..END_DOY).each do |doy|
        # print "doy #{doy}.."; $stdout.flush
        averages[doy] = cumulate_array

        for lati_index in (0..MAX_Y_INDEX)
          for longi_index in (0..MAX_X_INDEX)
            for year in (start_year..end_year)
              # Does this year have this DOY?
              if min = min_grids[year].get_by_index(longi_index,lati_index,doy)
                max = max_grids[year].get_by_index(longi_index,lati_index,doy)
                begin
                  averages[doy][lati_index][longi_index] += (max + min) / 2.0
                  if lati_index == 2 && longi_index == 22
                    # puts "year #{year} doy #{doy}, min #{min} max #{max} avg #{averages[doy][lati_index][longi_index]}"
                  end
                rescue Exception => e
                  puts "BORKED!\nlati #{lati_index}, longi #{longi_index}, avgs[doy] #{averages[doy].inspect}"
                  raise e
                end
              end
            end
          end
        end
      end
      # print "\ndoing the averaging. "
      # Now we have the sum of all the existing daily average temps. Divide by the number
      # of layers that had that DOY.
      (START_DOY..END_DOY).each do |doy|
        "doy #{doy}.."; $stdout.flush
        for lati_index in (0..MAX_Y_INDEX)
          for longi_index in (0..MAX_X_INDEX)
            begin
              raise 'zero in lfd' if layers_for_doy[doy] == 0
              averages[doy][lati_index][longi_index] /= layers_for_doy[doy]
            rescue Exception => e
              puts "BORKED on division! doy #{doy}, lati_index #{lati_index}, longi_index #{longi_index}, lfd[doy] #{layers_for_doy[doy]}"
              puts averages[doy][lati_index].inspect
              raise e
            end
          end
        end
      end
      # puts ""
      averages
    end

    def cumulate(min_grids,max_grids,averages,start_year=START_YEAR,end_year=END_YEAR,base=10.0,upper=30.0,fahrenheit=false)
      # construct a set of DD arrays, one per year
      yearly_DD_accums = {}
      # print "cumulating. "
      for year in start_year..end_year
        yearly_DD_accums[year] = cumulate_array
        # print "#{year}.."; $stdout.flush 
        for doy in (START_DOY..END_DOY)
          for lati_index in (0..MAX_Y_INDEX)
            for longi_index in (0..MAX_X_INDEX)
              begin
                min = min_grids[year].get_by_index(longi_index,lati_index,doy) || averages[doy][lati_index][longi_index]
                max = max_grids[year].get_by_index(longi_index,lati_index,doy) || averages[doy][lati_index][longi_index]
                if fahrenheit
                  min = to_fahrenheit(min)
                  max = to_fahrenheit(max)
                  base = to_fahrenheit(base) if base == 10.0
                  upper = to_fahrenheit(upper) if upper == 30.0
                end
                if block_given?
                  dd = yield(min,max,base,upper)
                else
                  dd = rect_DD(min,max,base,upper)
                end
                yearly_DD_accums[year][lati_index][longi_index] += dd
              rescue Exception => e
                puts "cumulate: problem at #{year}, #{doy}, #{lati_index}, #{longi_index}"
                raise e
              end
            end
          end
        end
      end
      # puts ""
      yearly_DD_accums
    end

    def year_dd_grid(max_grids,min_grids,year)
      return {1 => 4, 6 => 5}
    end

    # For a given year, return a hash of DOYs at a grid point with the daily DDs for each, using the passed-in block to calculate a day's DD
    def dds_for_year_at_point(p)
      calculate_fahrenheit = p[:calculate_fahrenheit] || true
      base = p[:base] || 50.0
      upper = p[:upper] || 86.0
      start_doy = p[:start_doy] || START_DOY # May 1
      [:max_grids,:min_grids,:year,:lati_index,:longi_index].each { |sym| raise "Required param #{sym.to_s} missing" unless p[sym] }
      doy_dds = {} # Will be a Hash keyed by DOY
  
      (start_doy..366).each do |doy|
        min = p[:min_grids][p[:year]].get_by_index(p[:longi_index],p[:lati_index],doy)
        max = p[:max_grids][p[:year]].get_by_index(p[:longi_index],p[:lati_index],doy)
        next unless min && max
        if block_given?
          doy_dds[doy] = yield(to_fahrenheit(min),to_fahrenheit(max),base,upper)
        else
          doy_dds[doy] = modB_DD(to_fahrenheit(min),to_fahrenheit(max),base,upper)
        end
      end
      doy_dds
    end

    def frost_doy(grid,longi_index,lati_index,frost_value=0.0)
      (START_OF_JULY..366).each do |doy|
        min = grid.get_by_index(longi_index,lati_index,doy)
        if min && min <= frost_value
          return doy
        end
      end
      nil
    end

    def remaining_dds_for_year_at_point(dds_at_point,frost_doy,start_doy=120)
      remaining_dds = {}
      sum = 0
      frost_doy.to_i.downto(start_doy) do |doy|
        next unless dds_at_point[doy]
        sum += dds_at_point[doy]
        remaining_dds[doy] = sum
      end
      remaining_dds
    end

    # Return a hash of remaining-DD values for a grid point up to the first frost for that year.
    # Most of the params get passed unchanged to dds_for_year_at_point, which handles defaults and such.
    # FIXME: Extend interface to include a passed-in block for DD calcs. For now,
    # just uses dds_for_year_at_point's, which is ModB / 50.0 / 86.0
    def pre_frost_remaining_dds_at_point(p,proc=nil)
  
      frost_value = p[:frost_value] || 0.0
      [:max_grids,:min_grids,:year,:lati_index,:longi_index].each { |sym| raise "Required param #{sym.to_s} missing" unless p[sym] }
      fd = frost_doy(p[:min_grids][p[:year]],p[:longi_index],p[:lati_index],frost_value)
      return nil unless fd
      if block_given?
        dds = dds_for_year_at_point(p,&proc)
      else
        dds = dds_for_year_at_point(p)
      end
      [remaining_dds_for_year_at_point(dds,fd),fd]
    end

    # Return a hash, by doy, of the median remaining-DD value for that doy over all years for a point
    def median_pre_frost_remaining_dds(p)
      # hash by year of per-day remaining DDs
      remaining = {}
      [:min_grids,:max_grids,:years,:longi_index,:lati_index].each { |sym| raise "Required param #{sym.to_s} missing" unless p[sym] }
      # Assemble a dataset of remaining DDs for this point; it'll be a hash (by year) of hashes (by doy) of remaining DD
      p[:years].each do |year|
        p[:year] = year # Hack the param hash so it's good to go for pre_frost_remaining_dds_at_point
        remaining[year],frost_doy = pre_frost_remaining_dds_at_point(p)
      end
      # Iterate over each possible DOY, find the median for that DOY. Will pointlessly access many nonexistent DOYs after
      # first frost, but that means we don't terminate prematurely if a DOY happens to be missing
      medians = {}
      (START_DOY..366).each do |doy|
        dds_for_doy = (p[:years].collect {|year| remaining[year][doy]}).compact
        next unless dds_for_doy.size > 0
        medians[doy] = median(dds_for_doy)
      end
      medians
    end

    def print_samples(yearly_DD_accums,start_year=START_YEAR,end_year=END_YEAR)
      for year in start_year..end_year
        print "\n#{year}:"
        (0..30).step(5) do |longi_index|
          (0..20).step(5) do |lati_index|
            print "#{yearly_DD_accums[year][longi_index][lati_index]}, "
          end
        end
        puts ""
      end
    end
  end
end
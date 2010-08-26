class DuplicateClientsReport < Report
  SAME_NAME = 1
  SAME_SPOUSE_NAME = 2
  SAME_ACCOUNT_NUMBER = 4
  attr_accessor :date

  def initialize (params,dates, user)
#    @date = dates.blank? ? Date.today : dates[:date]
#    @name   = "Report from #{@from_date} to #{@to_date}"
    get_parameters(params, user)
  end

  def name
    "Duplicate Clients"
  end

  def self.name
    "Client Duplications Report"
  end

  def generate
    generate2
  end

  def generate1
    data = [] #account number can be nil, others cannot be 
    duplicates = [] #elements of this array will be hash of type {id1, :id2, :duplicacy_level}
    i=0
    Client.all.each do |c|
      if i>2000
        break
      end
      data.push([soundex1(c.name), soundex1(c.spouse_name), c.account_number, c.id])
      j = 0
      while j < data.length-1
        duplicacy_level = 0
        if data[j][0] == data.last[0] then duplicacy_level+=SAME_NAME end
        if data[j][1] == data.last[1] then duplicacy_level+=SAME_SPOUSE_NAME end
        if (data[j][2] != nil) and (data[j][2].length=="") and (data[j][2] == data.last[2]) then duplicacy_level+=SAME_ACCOUNT_NUMBER end
        if duplicacy_level>0
          duplicates.push([data[j][3], data.last[3], duplicacy_level])
        end
        j+=1
      end
      i+=1
    end
    return duplicates
  end

  def soundex1(string)
    copy = string.upcase.tr '^A-Z', ''
    return "" if copy.empty?
    first_letter = copy[0]
    copy.tr_s! 'AEHIOUWYBFPVCGJKQSXZDTLMNR', '00000000111122222222334556'
    copy.sub!(/^(.)\1*/, '').gsub!(/0/, '')
    return "#{first_letter}#{copy.ljust(3,"0")}".to_i
  end

  def generate2
    data = [] #account number can be nil, others cannot be 
    name_and_id = Hash.new
    spouse_name_and_id = Hash.new
    account_num_and_id = Hash.new
    duplicates = Hash.new

    i=0
    Client.all(:fields => [:id, :name, :spouse_name, :account_number]).each do |c|
#      if i>1000
#        break
#      end
      i+=1
      #duplicate first name
      name_firstchar, name_rest = soundex2(c.name)
      if name_and_id[name_firstchar] == nil
        name_and_id[name_firstchar] = Array.new
      end
      name_and_id[name_firstchar].push ({:rest => name_rest, :id => c.id})
      j = 0
      last = name_and_id[name_firstchar].length-1 
      while j<last
        if name_and_id[name_firstchar][j][:rest] == name_rest

          duplicates[ [c.id, name_and_id[name_firstchar][j][:id]] ] = SAME_NAME
        end
        j+=1
      end

      #duplicate spouse name
      spouse_name_firstchar, spouse_name_rest = soundex2(c.spouse_name)
      if spouse_name_and_id[spouse_name_firstchar] == nil
        spouse_name_and_id[spouse_name_firstchar] = Array.new
      end
      spouse_name_and_id[spouse_name_firstchar].push ({:rest => spouse_name_rest, :id => c.id})
      j = 0
      last = spouse_name_and_id[spouse_name_firstchar].length-1 
      while j<last
        if spouse_name_and_id[spouse_name_firstchar][j][:rest] == name_rest
          duplicates[ [c.id, spouse_name_and_id[spouse_name_firstchar][j][:id]] ] = SAME_SPOUSE_NAME | duplicates[ [c.id, spouse_name_and_id[spouse_name_firstchar][j][:id]] ].to_i
        end
        j+=1
      end

      if(c.account_number != nil) and (c.account_number.length != 0) and (c.account_number.to_i != 0)
        if account_num_and_id[c.account_number] != nil
          duplicates[ [c.id, account_num_and_id[c.account_number]] ] = SAME_ACCOUNT_NUMBER | duplicates[ [c.id, account_num_and_id[c.account_number]] ].to_i
        else
          account_num_and_id[c.account_number] = c.id
        end
      end
    end

    arr = [] #this will the arr to be returned consisting of ID1, ID2 and issue
    duplicates.each do |key,value|
      arr.push([key[0], key[1], value])
    end
    arr.sort! { |a,b| 
      b[2] <=> a[2]} #this sorts array in desecending order
    return arr
  end

  def soundex2(string)
    copy = string.upcase.tr '^A-Z', ''
    return "" if copy.empty?
    first_letter = copy[0,1]
    copy.tr_s! 'AEHIOUWYBFPVCGJKQSXZDTLMNR', '00000000111122222222334556'
    copy.sub!(/^(.)\1*/, '').gsub!(/0/, '')
    return first_letter, copy.ljust(3,"0").to_i
  end
end


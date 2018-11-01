module Fias
  module Name
    module Canonical
      class << self
        def canonical(name)
          result = search(name) || search_exception(name)
          result || fail("Unknown abbrevation: #{name}")
          fix_republic_case(result)
        end

        def supercanonical(name)
          result_array = []
          result_actual =  search_s(name) || search_exception(name)
          result_new = result_actual || name #fail("Unknown abbrevation: #{name}")
          result_new == name ?  (result_array):(
          result_new.map do |result|
            current_hash = kind_pointer(((result.sort_by {|qwe| qwe.length}).reverse))
            current_hash[:spelling_variants] = fix_republic_case(result)
            # current_hash["value_column"] = field_name_pointer(result)
            result_array << current_hash
          end)
          result_array
        end

        private

          def empty_hash_maker(incorrect_type)
            hash = Hash.new {}
            hash[:object_kind] = ""
            hash[:spelling_variants] = incorrect_type
            hash
          end

          def kind_pointer(type_vars)
            hash = Hash.new{}
            type_vars.map do |typo|
              pointer(hash,typo)
            end
            hash
          end

          def pointer(one_hash, typo)
            break_flag = 0
            var = CONSTANTS
            var.map do |element|
              if element[:type].include?(typo)
                one_hash[:spelling_variants] = typo
                one_hash[:value_column] = element[:field_name]
                one_hash[:type_column] =  element[:field_type]
                one_hash[:object_kind] = element[:kind]
                break_flag = 1
                break
              end
              if break_flag == 1
                break
              end
            end
            if one_hash.empty?
              one_hash[:spelling_variants] = typo
              one_hash[:value_column] = var.last[:field_name]
              one_hash[:type_column] =  var.last[:field_type]
              one_hash[:object_kind] = var.last[:kind]
            end
            one_hash
          end

          def search(key)
            long = Fias.config.index[Unicode.downcase(key)]

            return nil unless long
            short = short_for(long)
            short_stripped = short_for(long).gsub(/\.$/, '')
            [long, short_stripped, short, aliases_for(long)].flatten.compact
          end

          def search_s(key)
            #long_arr = FiasAddressObjectType.where("scname='#{new_key}' OR socrname='#{new_key}' OR scname='#{second_key}' OR socrname='#{second_key}'").pluck(:socrname)
            flag = 0
            final_arr = []
            long_arr = Fias.config.index[Unicode.downcase(key)]

            #begin
            long_arr.nil? ? (flag = 1; final_arr = nil) : (long_arr = long_arr.uniq)
            #rescue
            #  byebug
            #end
            if flag != 1
              long_arr.map do |long|
                return nil unless long
                short = short_for(long)
                short_stripped = short_for(long).gsub(/\.$/, '')
                final_arr << [long, short_stripped, short, aliases_for(long)].flatten.compact.uniq
              end
            end
            final_arr
          end

          def short_for(long)
            Fias.config.shorts[Unicode.downcase(long)] || long
          end

          def aliases_for(long)

            Fias.config.aliases[Unicode.downcase(long)]
          end

          def search_exception(name)

            Fias.config.exceptions[Unicode.downcase(name)]
          end

          def fix_republic_case(canonical)
            return canonical unless canonical[0] == REPUBLIC
            canonical.map { |n| Unicode.upcase(n[0]) + n[1..-1] }
          end
      end
      CONSTANTS = [

          {
              type:['Вадение','Дом','Домовладение','Здание','Объект незавершенного строительства','Сооружение','Гараж','Подвал','Котельная',
                    'Погреб'],
              :field_type => nil,
              field_name: 'housenum',
              kind: 'house'
          },

          {
              type: ['Корпус'],
              field_type:nil,
              field_name:'strucnum',
              kind: 'house'
          },

          {
              type:['Строение'],
              field_type:nil,
              field_name:'buildnum',
              kind: 'house'
          },

          {
              type:['Квартира','Офис','Павильон','Помещение','Рабочий участок','Склад','Торговый зал','Цех'],
              field_type:'flattype',
              field_name:'flatnumber',
              kind: 'room'
          },

          {
              type:['Комната'],
              field_type:'roomtypeid',
              field_name:'roomnumber',
              kind: 'room'
          },

          {
              type:['Участок','Земельный участок','участок','земельный участок'],
              field_type:nil,
              field_name:'number',
              kind: 'stead'
          },
          {
              type:[''],
              field_type: 'shortname',
              field_name: 'formalname',
              kind: 'address'
          }
      ]


      REPUBLIC = 'республика'
    end
  end
end
#!/bin/ruby -w

#
# this script verifies your rolls on the bitcoin gambling site dadice.com 
# fill the needed values below, safe and run
#
# like it so much you want to send me some coins?
# -> 1NvJcTefTTsc8nYKAHoNfBe5mrBpHX2zb2
# 
# found a bug?
# -> shor3na@gmail.com
# 

require 'digest/sha2'
require 'openssl'

### SET THESE VALUES AS NEEDED ###

$verbose = false # set to true for easier debugging
$client_seed           = "PS9zaMo49uhMoENfHZD0GIMVdLInFB"
$sha256_of_server_seed = "df017d5bdb1bc86bc80910ae0ebd4d0a7898bf3f32127c6d1fb548d9a2ac4fe2"
$server_seed           = "ede2a2e86b02649f7c7e5ad5eb31a74d27be694b81c1de7adf7e31f5db806c99"
$start_nounce          = 0
$end_nounce            = 18

def simulate_roll(server_seed, client_seed, nounce)
    # must be defined here in order to use it after the loop finishes
    modulo_10000_of_converted_reduced_seed = 0
    
    # concat client seed and nounce to a single string
    seed = "#{client_seed}-#{nounce}"
    puts "seed: #{seed}" if $verbose
    
    digest = OpenSSL::Digest.new('sha512')
    seed = OpenSSL::HMAC.hexdigest(digest,server_seed,seed)
    puts "hmac-sha512(seed): #{seed}" if $verbose
    puts seed.length if $verbose
    i = 0 #counts the number of iterations for the loop
    # i will also be used below to shift the 5 digits we take should 
    # the current selection result in bias towards certain rolls
    loop do  
        # keep only 5 digits
        reduced_hashed_string = seed[(0+(i*5))..(4+(i*5))]
        puts "reduced seed: #{reduced_hashed_string}" if $verbose
    
        # convert reduced hash to Integer
        converted_reduced_hashed_seed = reduced_hashed_string.to_i(16)
        puts "reduced hash to int: #{converted_reduced_hashed_string}" if $verbose
        
        # modulo 10000 the integer
        modulo_10000_of_converted_reduced_seed = converted_reduced_hashed_seed % 10**4
        puts "reduced hash to int mod 10^4: #{modulo_10000_of_converted_reduced_seed}" if $verbose    
        
        # remove bais towards certain rolls
        # this is done by taking the next 5 digits of the seed
        # if less than 5 digits are left, the loop breaks and returns 9999
         
        i += 1
        if (i >= (seed.length / 5)) # true if 4 or less digits left
            modulo_10000_of_converted_reduced_hashed_seed = 9999
            break
        end
        break if (converted_reduced_hashed_seed <= 999999)
    end
    return modulo_10000_of_converted_reduced_seed
end

calculated_sha256_of_server_seed = Digest::SHA256.hexdigest($server_seed)
if (calculated_sha256_of_server_seed == $sha256_of_server_seed)
    puts "#{"="*34} SEED  DATA #{"="*34}"
    puts "Hash of Server is correct.\n-> #{$sha256_of_server_seed}"
    puts "Client seed was given as\n-> #{$client_seed}"
    puts "#{"="*36} ROLLS #{"="*37}"
    for i in $start_nounce..$end_nounce
        puts "Roll \##{i}: #{simulate_roll($server_seed, $client_seed, i).to_s.rjust(4,'0')}"
    end
else
    puts "#{"="*34} SEED  DATA #{"="*34}"
    puts "Warning! Hash of Server seed is not correct!.\nHash was given as:\n-> #{$sha256_of_server_seed}\nbut should be\n-> #{calculated_sha256_of_server_seed}\nfor given seed\n-> #{$server_seed}"
    puts "="*80
end


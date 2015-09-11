class MovieData
	attr_reader :train_file, :test_file, :train_hash, :movie_hash

	def initialize(direct_name, file_name = "u.data")  # if file_name is empty, default
		if file_name == "u.data"
			train_name =  "./" + direct_name + "/" + file_name
			test_file = nil
		else
			#when file_name is not empty
			train_name = "./" + direct_name + "/" + file_name.to_s + ".base"
			test_name = "./" + direct_name + "/" + file_name.to_s + ".test"
			@test_file = File.open(test_name)
		end
		@train_file = File.open(train_name)
		@train_hash = {}
		@movie_hash = {}
		load_data
	end

	#load data into train and movie hash
	def load_data
		load_train_or_test(train_file,train_hash)
		load_movie_hash(train_file, movie_hash)
	end

	#load data from a file
	def load_train_or_test(file_name, hash_name)
		#hash key is user_id, value is a hash table whose keys are movie_id
		train_file.seek(0)
		if file_name != nil
			file_name.each_line do |line|
				splited = line.split(" ")
				user_id = splited[0].to_i
				movie_id = splited[1].to_i
				rating = splited[2].to_i
				timestamp = splited[3].to_i
				if not hash_name.has_key?(user_id)  #if a user is not hashed, initialize the value to be a hash
					hash_name[user_id] = {}
				end
				hash_name[user_id][movie_id] = {rating: rating, timestamp: timestamp}
			end
		end
	end

	def load_movie_hash(file_name,hash_name)
		#hash key is movie_id, value is a hash table whose keys are user_id
		train_file.seek(0)
		if file_name != nil
			file_name.each_line do |line|
				splited = line.split(" ")
				user_id = splited[0].to_i
				movie_id = splited[1].to_i
				rating = splited[2].to_i
				timestamp = splited[3].to_i
				if not hash_name.has_key?(movie_id)  #if a user is not hashed, initialize the value to be a hash
					hash_name[movie_id] = {}
				end
				hash_name[movie_id][user_id] = {rating: rating, timestamp: timestamp}
			end
		end
	end


	#return the rating of a user in train data
	def rating(user_id, movie_id)
		if not train_hash.has_key?(user_id)   #user_id not valid
			puts "no such user"
		else
			if not train_hash[user_id].has_key?(movie_id)   #movie not seen return 0
				return 0
			else
				return train_hash[user_id][movie_id][:rating]    #if exist return rating
			end
		end
	end

	#return a list of movie
	def movies(user_id)
		if not train_hash.has_key?(user_id)
			puts "no such user"
		else
			train_hash[user_id].keys
		end
	end

	#return a list of user_id who have watched the given movie
	def viewers(movie_id)
		return movie_hash[movie_id].keys
	end

	#predict: calculate the average rating of a movie, and the average deviation of rating of a user,
	#add the average rating of user to the average rating of the movie
	def predict(user_id, movie_id)
		movie_avg = movie_avg(movie_id)
		user_deviation = user_deviation(user_id)
		predict = movie_avg + user_deviation
		if predict < 1
			return 1.0
		elsif predict > 5
			return 5.0
		else
			return predict	
		end	
	end

	#give the average rating of a given movie
	def movie_avg(movie_id)
		sum = 0
		count = 0
		if not movie_hash.has_key?(movie_id)
			return 3
		end
		movie_hash[movie_id].values.each do |user|
			sum += user[:rating]
			count += 1
		end
		return sum.to_f / count
	end


	#give the average of the errorerence between a user's ratings and average ratings
	def user_deviation(user_id)
		sum = 0.0
		count = 0
		train_hash[user_id].keys.each do |movie_id|
			rating = train_hash[user_id][movie_id][:rating]
			sum += rating - movie_avg(movie_id)    #sum of errorerence between a user's rating and average rating
			count += 1
		end
		return sum / count
	end

	#create a MovieTest object, set default to be -1
	def run_test(num = -1)
		pred_list = []
		count = 0
		test_file.each_line do |line|
			splited = line.split(" ")
			user_id = splited[0].to_i
			movie_id = splited[1].to_i
			rating = splited[2].to_i
			predict = predict(user_id,movie_id)
			error = (rating - predict).abs
			pred_list << {user_id: user_id, movie_id: movie_id, rating: rating, predict: predict,error: error}
			count += 1
			#if num is -1 the default value, then run all of the tests
			#if num is positive then check to stop
			if count >= num and num > 0
				break
			end
		end
		return MovieTest.new(pred_list)
	end


	#return the hash table of train data
	def put_train
		puts train_hash
	end

	#return the hash table of test data or no such file
	def put_test
		if test_hash == nil
			puts "no testing file"
		else
			puts test_hash
		end
	end
end


class MovieTest
	attr_reader :pred_list

	def initialize(pred_list)
		@pred_list = pred_list
	end

	#the length of of predication list
	def size
		pred_list.length
	end

	#the mean of the predict error
	def mean
		sum = 0
		pred_list.each do |pred|
			sum += pred[:error]
		end
		return sum / size
	end

	#the standard deviation of the predict error
	def stddev
		sum = 0
		m = mean
		pred_list.each do |pred|
			sum += (pred[:error] - m) ** 2
		end
		return Math.sqrt(sum / size)
	end

	#the root square error of prediction error
	def rms
		sum = 0
		pred_list.each do |pred|
			sum += pred[:error] ** 2
		end
		return Math.sqrt(sum / size)
	end

	#list all the predict results
	def to_a
		pred_list.each do |pred|
			puts "\[#{pred[:user_id]}, #{pred[:movie_id]}, #{pred[:rating]}, #{pred[:predict]} \]"
		end
		puts "over"
	end
end

# movie_data = MovieData.new("ml-100k")
movie_data= MovieData.new('ml-100k',:u1) 
# movie_data.put_train
# puts movie_data.rating(4,303)
# puts movie_data.movies(4)
# puts movie_data.viewers(303)
# puts movie_data.viewers2(303)
puts movie_data.movie_avg(303)

# puts movie_data.user_deviation(1)
# puts movie_data.predict(1,6)
# movie_data.put_test
puts Time.now
test = movie_data.run_test
puts Time.now
# puts test.size
puts "mean #{test.mean}"
#puts test.to_a
puts "stddev: #{test.stddev}"
puts "rms : #{test.rms}"
puts test.size
# f = File.open("./ml-100k/u1.base")
# f.each_line do |line|
# 	puts line
# end
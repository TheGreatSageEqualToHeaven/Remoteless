local module = {}

function module.new()
	return { Locked = false, WaitingThreads = { } }
end

function module.lock(mutex)
	local lock_time = os.clock()
	local was_locked = false 

	if mutex.Locked then
		table.insert(mutex.WaitingThreads, coroutine.running())
		coroutine.yield()
		was_locked = true
	end

	mutex.Locked = true

	return was_locked, os.clock() - lock_time
end

function module.timedlock(mutex, delay_time)
	if mutex.Locked then
		table.insert(mutex.WaitingThreads, coroutine.running())
		coroutine.yield()
	end

	mutex.Locked = true

	task.delay(delay_time, function()
		if mutex.Locked == true then
			module.unlock(mutex)
		end
	end)
end

function module.unlock(mutex)
	if mutex.Locked == false then
		return
	end

	mutex.Locked = false 

	local waiting_threads = mutex.WaitingThreads

	if #waiting_threads > 0 then
		task.spawn(waiting_threads[1])
		table.remove(waiting_threads, 1)
	end
end

function module.cleanunlock(mutex)
	if mutex.Locked == false then
		return
	end

	mutex.Locked = false 

	local waiting_threads = mutex.WaitingThreads

	for i, thread in waiting_threads do 
		coroutine.close(thread)
	end
	
	table.clear(waiting_threads)
end

return module
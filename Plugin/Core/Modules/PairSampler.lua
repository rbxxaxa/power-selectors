local function createPairSampler(alreadySampled, sampleCache, pairGen, sampleFunc)
	return coroutine.wrap(
		function()
			local function cantorPair(a, b)
				return 0.5 * (a + b) * (a + b + 1) + b
			end

			while true do
				local x, y = pairGen()
				if x == nil then
					return nil
				end

				local idx = cantorPair(x, y)
				if not alreadySampled[idx] then
					alreadySampled[idx] = true
					local result = sampleFunc(x, y)
					sampleCache[idx] = result

					coroutine.yield(false, result)
				else
					coroutine.yield(true, sampleCache[idx])
				end
			end
		end
	)
end

return {
	create = createPairSampler
}

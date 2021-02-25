local LibDeflate = LibStub:GetLibrary("LibDeflate")
local LibSerialize = LibStub("LibSerialize")

function WorldOfParkour:CompressCourseData(savedCourse)
    local configForLS = {errorOnUnserializableType = false}
    -- Serialize
    local serializedCourse = LibSerialize:SerializeEx(configForLS, savedCourse)
    -- Compress
    return LibDeflate:CompressDeflate(serializedCourse)
end

function WorldOfParkour:CreateSharableString(compressedCourseData)
    -- Encode
    local encoded = "!WOP:1!"
    return encoded .. LibDeflate:EncodeForPrint(compressedCourseData)
end

local function compareTableTypes(tableA, tableB, errMsg)
    for k, _ in pairs(tableA) do
        if tableB[k] == nil then
            -- Additional field found.
            error(errMsg)
        end
        if type(tableA[k]) ~= type(tableB[k]) then
            -- Types don't match.
            error(errMsg)
        end
    end
end

local function validateDeserializedData(deserializedResults)
    -- We need to make sure the deserialized data isn't going to break our addon...
    if type(deserializedResults) ~= "table" then error("validateDeserializedData: Invalid import data.") end
    local errMsg = "validateDeserializedData: Bad Import"
    -- Check if the course keys are correct.
    local newCourse = WorldOfParkour:NewCourseDefaults()
    compareTableTypes(deserializedResults, newCourse, errMsg)

    -- Check if the point keys are correct.
    local newCoursePoint = WorldOfParkour:CreateCoursePoint({})
    for _, maybeCoursePoint in pairs(deserializedResults.course) do
        compareTableTypes(maybeCoursePoint, newCoursePoint, errMsg)
    end

    -- We are still not 100% sure that this is valid data, but we have
    -- errors checks in place down the line that should take care of it for us.
    return deserializedResults
end

function WorldOfParkour:ImportSharableString(sharableCourseString)
    local _, _, encodeVersion, encoded = string.find(sharableCourseString, "^(!WOP:%d+!)(.+)$")
    if encodeVersion then
        encodeVersion = tonumber(string.match(encodeVersion, "%d+"))
    else
        error("ImportSharableString: Bad import string.")
    end

    -- Decode
    local compress_deflate = LibDeflate:DecodeForPrint(encoded)
    -- Decompress
    local decompress_deflate = LibDeflate:DecompressDeflate(compress_deflate)
    if decompress_deflate == nil then error("LibDeflate: Decompression failed.") end
    -- Deserialize
    local isSuccess, deserializedResults = LibSerialize:Deserialize(decompress_deflate)
    if not isSuccess then error("LibSerialize: Error deserializing " .. deserializedResults) end
    local courseDetails = validateDeserializedData(deserializedResults)

    local foundId = FindSavedCourseKeyById(self.savedCoursesStore.savedcourses, courseDetails.id)
    -- Check if id is unique
    if foundId then
        -- id was not unique... make a new one.
        courseDetails.id = UUID()
    end

    -- Reset course completion
    WorldOfParkour:ResetCourseCompletion(courseDetails)

    -- Add to saved courses.
    WorldOfParkour:InsertToSavedCourses(courseDetails)
    return courseDetails.id
end

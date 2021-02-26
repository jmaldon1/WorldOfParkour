local LibDeflate = LibStub:GetLibrary("LibDeflate")
local LibSerialize = LibStub("LibSerialize")

function WorldOfParkour:CompressCourseData(savedCourse)
    -- These are keys we don't want in our compressed data.
    local keysToSkip = {compressedcoursedata = true}
    local savedCourseCopy = {}

    for k, v in pairs(savedCourse) do
        if not SetContains(keysToSkip, k) then
            savedCourseCopy[k] = v
        end
    end
    local configForLS = {errorOnUnserializableType = false}
    -- Serialize
    local serializedCourse = LibSerialize:SerializeEx(configForLS, savedCourseCopy)
    -- Compress
    return LibDeflate:CompressDeflate(serializedCourse)
end

function WorldOfParkour:CreateSharableString(compressedCourseData)
    -- Encode
    local encoded = "!WOP:1!"
    return encoded .. LibDeflate:EncodeForPrint(compressedCourseData)
end

local function compareTableTypes(tableA, tableB)
    local errMsg = "compareTableTypes: Bad Import"
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
    -- Check if the course keys are correct.
    local newCourse = WorldOfParkour:NewCourseDefaults()
    compareTableTypes(deserializedResults, newCourse)

    -- Check if the point keys are correct.
    local newCoursePoint = WorldOfParkour:CreateCoursePoint({})
    for _, maybeCoursePoint in pairs(deserializedResults.course) do
        compareTableTypes(maybeCoursePoint, newCoursePoint)
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

    -- Pick what data we want imported over from the old course.
    local newSavedCourse = WorldOfParkour:NewCourseDefaults()
    newSavedCourse.title = courseDetails.title
    newSavedCourse.description = courseDetails.description
    newSavedCourse.course = courseDetails.course
    newSavedCourse.difficulty = courseDetails.difficulty
    newSavedCourse.lastmodifieddate = courseDetails.lastmodifieddate
    newSavedCourse.compressedcoursedata = WorldOfParkour:CompressCourseData(newSavedCourse)

    WorldOfParkour:ResetCourseCompletion(newSavedCourse)

    -- Add to saved courses.
    WorldOfParkour:InsertToSavedCourses(newSavedCourse)
    return newSavedCourse.id
end

local LibDeflate = LibStub:GetLibrary("LibDeflate")
local LibSerialize = LibStub("LibSerialize")

local _, addon = ...
local utils = addon.utils

local function trimCourseDetails(courseDetails)
    local keysToSkip = {compressedcoursedata = true}
    local courseDetailsTrimmed = {}

    for k, v in pairs(courseDetails) do
        if not utils.setContains(keysToSkip, k) then courseDetailsTrimmed[k] = v end
    end
    return courseDetailsTrimmed
end

function WorldOfParkour:CompressCourseData(savedCourseDetails)
    -- These are keys we don't want in our compressed data.
    local savedCourseDetailsTrimmed = trimCourseDetails(savedCourseDetails)

    local configForLS = {errorOnUnserializableType = false}
    -- Serialize
    local serializedCourse = LibSerialize:SerializeEx(configForLS, savedCourseDetailsTrimmed)
    -- Compress
    return LibDeflate:CompressDeflate(serializedCourse)
end

local function createCourseStringHash(printableEncode)
    local hashInteger = LibDeflate:Adler32(printableEncode)
    local hashHex = utils.decimalToHex(hashInteger)
    return string.format("0x%08s", hashHex)
end

function WorldOfParkour:CreateSharableString(compressedCourseData)
    -- Encode
    local encoded = "!WOP:2!"
    local printableEncode = LibDeflate:EncodeForPrint(compressedCourseData)
    local hash = createCourseStringHash(printableEncode) .. "!"
    return encoded .. hash .. printableEncode
end

local function compareTableTypes(tableA, tableB)
    local errMsg = "compareTableTypes: Bad Import, "
    for k, _ in pairs(tableA) do
        if tableB[k] == nil then
            -- Additional field found.
            WorldOfParkour:Error(errMsg .. "additional field found.")
        end
        if type(tableA[k]) ~= type(tableB[k]) then
            -- Types don't match.
            WorldOfParkour:Error(errMsg .. "type mismatch.")
        end
    end

    for k, _ in pairs(tableB) do
        if tableA[k] == nil then
            -- Missing field. 
            WorldOfParkour:Error(errMsg .. "missing field.")
        end
    end
end

local function validateDeserializedData(deserializedResults)
    -- We need to make sure the deserialized data isn't going to break our addon...
    if type(deserializedResults) ~= "table" then
        WorldOfParkour:Error("validateDeserializedData: Invalid import data.")
    end
    -- Check if the course keys are correct.
    local newCourseDetails = WorldOfParkour:NewCourseDefaults()
    local newCourseDetailsTrimmed = trimCourseDetails(newCourseDetails)
    compareTableTypes(deserializedResults, newCourseDetailsTrimmed)

    -- Check if the point keys are correct.
    local newCoursePoint = WorldOfParkour:CreateCoursePoint({})
    for _, maybeCoursePoint in pairs(deserializedResults.course) do
        compareTableTypes(maybeCoursePoint, newCoursePoint)
    end

    -- We are still not 100% sure that this is valid data, but we have
    -- errors checks in place down the line that should take care of it for us.
    return deserializedResults
end

function WorldOfParkour:ParseSharableString(sharableCourseString, _hashOnly)
    -- Returns version, hash, and encoded string
    -- Or an error if there was an issue.
    -- NOTE: Lua doesn't use regex, it uses Patterns (https://www.lua.org/manual/5.1/manual.html#5.4.1)
    local hashOnly = _hashOnly or false  -- Only parse the hash, O(1) operation

    local versionGroupPattern = "(!WOP:%d+!)"
    local hashGroupPattern = "(0x%x+!)"
    local encodedGroupPattern = "(.+)"

    local versionPattern = string.format("^%s", versionGroupPattern)
    local hashPattern = string.format("^%s%s", versionGroupPattern, hashGroupPattern)
    local encodedV1Pattern = string.format("^%s%s$", versionGroupPattern, encodedGroupPattern)
    local encodedPattern = string.format("^%s%s%s$", versionGroupPattern, hashGroupPattern, encodedGroupPattern)

    local _, _, encodeVersionRaw = string.find(sharableCourseString, versionPattern)
    if encodeVersionRaw then
        local encodeVersion = tonumber(string.match(encodeVersionRaw, "%d+"))
        if encodeVersion == 1 then
            if hashOnly then
                WorldOfParkour:Error("ParseSharableString: the `hashOnly` argument only works with course strings v2+.")
            end
            local _, _, _, encodedV1 = string.find(sharableCourseString, encodedV1Pattern)
            return encodeVersion, createCourseStringHash(encodedV1), encodedV1
        elseif encodeVersion > 1 then
            if hashOnly then
                local _, _, _, hash = string.find(sharableCourseString, hashPattern)
                return encodeVersion, hash, nil
            end
            local _, _, _, hash, encoded = string.find(sharableCourseString, encodedPattern)
            return encodeVersion, hash, encoded
        end
    else
        WorldOfParkour:Error("ImportSharableString: Bad import string.")
    end
end

function WorldOfParkour:ImportSharableString(sharableCourseString)
    local _, hash, encoded = self:ParseSharableString(sharableCourseString)
    -- Decode
    local compress_deflate = LibDeflate:DecodeForPrint(encoded)
    -- Decompress
    local decompress_deflate = LibDeflate:DecompressDeflate(compress_deflate)
    if decompress_deflate == nil then WorldOfParkour:Error("LibDeflate: Decompression failed.") end
    -- Deserialize
    local isSuccess, deserializedResults = LibSerialize:Deserialize(decompress_deflate)
    if not isSuccess then WorldOfParkour:Error("LibSerialize: Error deserializing " .. deserializedResults) end
    local courseDetails = validateDeserializedData(deserializedResults)

    -- Pick what data we want imported over from the old course.
    local newSavedCourse = WorldOfParkour:NewCourseDefaults()
    newSavedCourse.title = courseDetails.title
    newSavedCourse.description = courseDetails.description
    newSavedCourse.course = courseDetails.course
    newSavedCourse.difficulty = courseDetails.difficulty
    newSavedCourse.lastmodifieddate = courseDetails.lastmodifieddate
    newSavedCourse.compressedcoursedata = WorldOfParkour:CompressCourseData(newSavedCourse)
    -- There may exist old courses that do not have this data, so we default to empty string.
    newSavedCourse.wowversion = courseDetails.wowversion or ""
    newSavedCourse.creator = courseDetails.creator or ""

    WorldOfParkour:ResetCourseCompletion(newSavedCourse)

    -- Add to saved courses.
    WorldOfParkour:InsertToSavedCourses(newSavedCourse)
    return newSavedCourse.id, hash
end

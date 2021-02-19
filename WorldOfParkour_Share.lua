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
    return LibDeflate:EncodeForPrint(compressedCourseData)
end

function WorldOfParkour:ImportSharableString(sharableCourseString)
    -- Decode
    local compress_deflate = LibDeflate:DecodeForPrint(sharableCourseString)
    -- Decompress
    local decompress_deflate = LibDeflate:DecompressDeflate(compress_deflate)
    if decompress_deflate == nil then
        error("LibDeflate: Decompression failed.")
    end
    -- Deserialize
    local isSuccess, deserializedResults =
        LibSerialize:Deserialize(decompress_deflate)
    if not isSuccess then
        error("LibSerialize: Error deserializing " .. deserializedResults)
    end
    local course = deserializedResults

    local foundId = FindSavedCourseKeyById(self.savedCoursesStore.savedcourses,
                                           course.id)
    -- Check if id is unique
    if foundId then
        -- id was not unique... make a new one.
        course.id = UUID()
    end
    -- Add to saved courses.
    WorldOfParkour:InsertToSavedCourses(course)
    return course.id
end

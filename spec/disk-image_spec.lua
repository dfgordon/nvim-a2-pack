describe("picker", function()
    local dimg = require "disk-image"
    it("parse_dir", function()
        local rows = { "INT      3  APPLESOFT", "BIN      9  MASTER CREATE", "BIN      3  COPY.OBJ0",
        "BIN     27  MUFFIN" }
        dimg.parse_dir(rows)
        local actual = dimg.curr_listing
        local expected = {}
        expected["APPLESOFT"] = "INT"
        expected["MASTER CREATE"] = "BIN"
        expected["COPY.OBJ0"] = "BIN"
        expected["MUFFIN"] = "BIN"
        assert.are.same(actual,expected)
    end)
end)

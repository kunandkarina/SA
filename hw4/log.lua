local user_agent = ngx.var.http_user_agent
if user_agent and not ngx.re.find(user_agent, "no-logging") then
        ngx.req.read_body()
        local request_header = ngx.req.get_headers()
        local request_body = ngx.req.get_body_data()
        local response_header = ngx.resp.get_headers()
        local user_agent = ngx.var.http_user_agent

        local res = ngx.location.capture("/index.txt")
        local response_body = res.body
        --ngx.say(user_agent)
        ngx.say(res.body)

        local log = "Request Header:\n"
        for k,v in pairs(request_header) do
                log = log .. k .. ": " .. v .. "\n"
        end
        log = log .. "\n"
        log = log .. "Request Body:\n"
        if request_body then
                log = log .. request_body .. "\n"
        else
                log = log .. "\n"
        end


        log = log .. "\n"


        log = log .. "Response Header:\n"
        for k,v in pairs(response_header) do
                log = log .. k .. ": " .. v .. "\n"
        end
        log = log .. "\n"
        log = log .. "Response Body:\n"
        if response_body then
                log = log .. response_body
        end

        log = ngx.encode_base64(log)

        ngx.say("STATUS: " .. res.status .. " " .. log .. "\n")

-- write to log file --
        file_path = "/home/judge/webserver/log/access.log"
        local file, err = io.open(file_path, "a")
        if not file then
            ngx.log(ngx.ERR, "Failed to open log file: ", err)
            return
        end

        file:write("STATUS: " .. res.status .. " " .. log .. "\n")

        file:close()
--end
end
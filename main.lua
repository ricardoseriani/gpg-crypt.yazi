local selected_or_hovered = ya.sync(function()
    local tab, paths = cx.active, {}
    for _, u in pairs(tab.selected) do
        paths[#paths + 1] = u
    end
    if #paths == 0 and tab.current.hovered then
        paths[1] = tab.current.hovered.url
    end
    return paths
end)

return {
    entry = function(_, job)
        local action = job.args[1] if not action then
            return
        end

        local input_position = { "top-center", y = 3, w = 40 }

        if action == "encrypt" then
            local crypt_key, crypt_key_event = ya.input {
                title = "GPG encrypt key",
                obscure = true,
                position = input_position,
            }c
            local confirm_crypt_key, confirm_crypt_key_event = ya.input {
                title = "Confirm GPG encrypt key",
                obscure = true,
                position = input_position,
            }

            -- Check if The user has confirmed both inputs
            if crypt_key_event ~= 1 or confirm_crypt_key_event ~= 1 then
                return
            end

            -- Check if both key is equals
            if crypt_key ~= confirm_crypt_key then
                return
            end

            -- Encrypt files/directories
            for _, v in pairs(selected_or_hovered()) do
                if fs.cha(v).is_dir then
                    -- TODO: Check a way to use <() inside os.execute
                    local zipped = tostring(v)..".tar"
                    os.execute("tar -cf " .. zipped .. " " .. tostring(v))
                    os.execute("gpg --quiet --symmetric --output " .. zipped .. ".gpg --batch --passphrase " .. crypt_key .. " " .. zipped)
                    os.execute("rm " .. zipped)
                else
                    os.execute("gpg --quiet --symmetric --output " .. tostring(v) .. ".gpg --batch --passphrase " .. crypt_key .. " " .. tostring(v))
                end
            end
        end

        if action == "decrypt" then
            local crypt_key, crypt_key_event = ya.input {
                title = "GPG decrypt key",
                obscure = true,
                position = input_position,
            }

            -- Check if The user has confirmed input
            if crypt_key_event ~= 1 then
                return
            end

            -- Decrypt files/directories
            for _, v in pairs(selected_or_hovered()) do
                os.execute("gpg --decrypt --output " .. tostring(v):gsub(".gpg$","") .. " --batch --passphrase " .. crypt_key .. " " .. tostring(v))
            end
        end
    end,
}

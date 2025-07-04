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
            }

            -- Check if The user has confirmed input
            if crypt_key_event ~= 1 then
                return
            end

            local confirm_crypt_key, confirm_crypt_key_event = ya.input {
                title = "Confirm GPG encrypt key",
                obscure = true,
                position = input_position,
            }

            -- Check if The user has confirmed input
            if confirm_crypt_key_event ~= 1 then
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
                    local zipped = string.format("%s.tar", tostring(v))
                    os.execute(string.format("tar -cf '%s' '%s'",  zipped, tostring(v)))
                    os.execute(string.format("gpg --quiet --symmetric --output '%s.gpg' --batch --passphrase '%s' '%s'", zipped,  crypt_key, zipped))
                    os.execute(string.format("rm '%s'", zipped))
                else
                    os.execute(string.format("gpg --quiet --symmetric --output '%s.gpg' --batch --passphrase '%s' '%s'", tostring(v), crypt_key, tostring(v)))
                end
                ya.notify({
                    title = "GPG Encrypt",
                    content = "Encryption of file " .. v.name .. " was successfull",
                    timeout = 3,
                    level = "info",
                })

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
                ya.notify({
                    title = "GPG Decrypt",
                    content = "Decryption of file " .. v.name .. " was successfull",
                    timeout = 3,
                    level = "info",
                })
            end
        end
    end,
}

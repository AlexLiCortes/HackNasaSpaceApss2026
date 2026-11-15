        local btn = script.Parent
        local frame = btn.Parent
        btn.MouseButton1Click:Connect(function()
            frame.Visible = false
        end)
    
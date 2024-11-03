## qb-garages (old) integration, this part is also for the phone app
- you need to find this in your qb-garages server and client file
```lua
if v.state == 0 then
    v.state = Lang:t("status.out")
elseif v.state == 1 then
    v.state = Lang:t("status.garaged")
elseif v.state == 2 then
    v.state = Lang:t("status.impound")
elseif v.state == 3 then
    v.state = "Parked outside"
end
```
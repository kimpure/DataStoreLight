local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local base91 = require(ReplicatedStorage:WaitForChild('base91'))
local rbxzstd = require(ReplicatedStorage:WaitForChild('rbxzstd'))
local msgpack = require(ReplicatedStorage:WaitForChild('msgpack-luau'))

local PlayerData1 = {}
local PlayerData2 = {}
local PlayerBeforeDataInServer = {}

local DataStoreLight = {}


--// DataTable
DataStoreLight.DataTable = {
    eee = 0;
}

--// Setting
DataStoreLight.Setting = {
    Debug = false;
    ServerCompress = false;
}

--// DataStoreLight.Setting.Debug 가 true 일떄 파라미터들을 출력
function DataStoreLight:Debug(message , ...)
    if self.Setting.Debug then
        print(message , ...)
    end
end

--// 세션 회수가 초과했다면 기다림
function DataStoreLight:waitForRequest(requestType)
    local current = DataStoreService:GetRequestBudgetForRequestType(requestType)
	self:Debug(`남은 새션개수 : {current}`)
    while current < 1 do
        current = DataStoreService:GetRequestBudgetForRequestType(requestType)
        wait(1)
    end
end

--// Player 의 Data 를 DataStoreLight.DataTable 에 값에 있는 값들마다 로드
function DataStoreLight.load(Player:Player)
    for k,v in DataStoreLight.DataTable do
        DataStoreLight:Debug(`DataName : {k} , Player User Id : {Player.UserId}`)
        
        PlayerData1[Player.UserId] = {}
        PlayerData2[Player.UserId] = {}
        PlayerBeforeDataInServer[Player.UserId] = {}

        DataStoreLight:waitForRequest(Enum.DataStoreRequestType.GetAsync)
        local K1 = DataStoreService:GetDataStore(`{k}:1`):GetAsync(Player.UserId)

        DataStoreLight:waitForRequest(Enum.DataStoreRequestType.GetAsync)
        local K2 = DataStoreService:GetDataStore(`{k}:2`):GetAsync(Player.UserId)

        if DataStoreLight.Setting.ServerCompress then
            --//ServerCompress
            if K1 then

            
                local _o = string.sub(K1 , 1 , 1)
                K1 = string.sub(K1 , 2)

                if _o == '\20' then
                    DataStoreLight:Debug(`압축돼지 않은 데이터 : {K1}`)

                    K1 = msgpack.decode(msgpack.utf8Decode(K1))
                else
                    DataStoreLight:Debug(`압축돼어있는 데이터 : {K1}`)
                    
                    K1 = msgpack.decode(msgpack.utf8Decode(buffer.tostring(rbxzstd.decompress(base91.decodeString(K1)))))
                end

                PlayerData1[Player.UserId][k] = K1
            else

                PlayerData1[Player.UserId][k] = v
            end


            if K2 then


                local _o = string.sub(K2 , 1 , 1)
                K2 = string.sub(K2 , 2)

                if _o == '\20' then
                    DataStoreLight:Debug(`압축돼지 않은 데이터 : {K2}`)

                    K2 = msgpack.decode(msgpack.utf8Decode(K2))
                else
                    DataStoreLight:Debug(`압축돼어있는 데이터 : {K2}`)

                    K2 = msgpack.decode(msgpack.utf8Decode(buffer.tostring(rbxzstd.decompress(base91.decodeString(K2)))))
                end
                
                PlayerData2[Player.UserId][k] = K2
            end
        else
            --// ClientCompress , 매직넘버 있는상태로 바로 변수에 꽃아버림
            if K1 then
                PlayerData1[Player.UserId][k] = K1
            else
                if rbxzstd.compress(buffer.fromstring(msgpack.utf8Encode(msgpack.encode(v)))) then
                    PlayerData1[Player.UserId][k] =  `\30{base91.encodeBuffer(rbxzstd.compress(buffer.fromstring(msgpack.utf8Encode(msgpack.encode(v)))))}`
                else
                    PlayerData1[Player.UserId][k] =  `\20{msgpack.utf8Encode(msgpack.encode(v))}`
                end
                -- PlayerData1[Player.UserId][k] = msgpack.utf8Encode(msgpack.encode())
            end

            if K2 then
                PlayerData2[Player.UserId][k] = K2
            end
        end
    end
end

--// DataStoreLight 의 PlayerData 라는 저장돼어있는 테이블에서 Data 를 가져옴
function DataStoreLight.get(Player:Player , DataName:string) : {any}
    if PlayerData1[Player.UserId] then
        if PlayerData1[Player.UserId][DataName] ~= nil then
            local _Data1 = PlayerData1[Player.UserId][DataName] :: string
            local _Data2 = PlayerData2[Player.UserId][DataName] :: string

            if DataStoreLight.Setting.ServerCompress then
                --// ServerCompress

                return _Data1 , _Data2
            else
                --// ClientCompress

                local retrunData = {}

                if string.sub(_Data1 , 1 , 1) == '\30' then
                    --//압축됀 데이터
                    retrunData[1] = msgpack.decode(msgpack.utf8Decode(rbxzstd.decompress(base91.decodeString(string.sub(_Data1 , 2)))))
                else
                    --// 압축돼지 않은 데이터
                    retrunData[1] = msgpack.decode(msgpack.utf8Decode(string.sub(_Data1 , 2)))
                end

                if string.sub(_Data2 , 1 , 1) == '\30' then
                    --//압축됀 데이터
                    retrunData[2] = msgpack.decode(msgpack.utf8Decode(rbxzstd.decompress(base91.decodeString(string.sub(_Data2 , 2)))))
                else
                    --// 압축돼지 않은 데이터
                    retrunData[2] = msgpack.decode(msgpack.utf8Decode(string.sub(_Data2 , 2)))
                end

                return retrunData[1] , retrunData[2]
            end
        end
    end
end

--// DataStoreLight 의 PlayerData 라는 저장돼는 테이블의 DataName 을 Value 의 값으로 변경
--// 클라이언트 컴프레스일때는 앞에 매직넘버없이 base 91 로 스트링 변환 안한값이 들어올꺼임 즉 set 에서는매직넘버 + base91 스트링화를 해줘야함
function DataStoreLight.set<T>(Player:Player , DataName:string , Value:T)
    if PlayerData1[Player.UserId] then
        if PlayerData1[Player.UserId][DataName] ~= nil then
            if DataStoreLight.Setting.ServerCompress then
                if typeof(Value) == 'string' then
                    PlayerBeforeDataInServer[Player.UserId][DataName] = PlayerData2[Player.UserId][DataName]
                    PlayerData2[Player.UserId][DataName] = PlayerData1[Player.UserId][DataName]
                    PlayerData1[Player.UserId][DataName] = `\20{Value}`
                else
                    PlayerBeforeDataInServer[Player.UserId][DataName] = PlayerData2[Player.UserId][DataName]
                    PlayerData2[Player.UserId][DataName] = PlayerData1[Player.UserId][DataName]
                    PlayerData1[Player.UserId][DataName] = `\30{base91.encodeString(Value)}`
                end
            else
                PlayerBeforeDataInServer[Player.UserId][DataName] = PlayerData2[Player.UserId][DataName]
                    PlayerData2[Player.UserId][DataName] = PlayerData1[Player.UserId][DataName]
                    PlayerData1[Player.UserId][DataName] = Value
            end
        end
    end
end

--// DataStoreLight.DataTable 에 있는 Data 들을 하나하나 모두 저장
function DataStoreLight.save(Player:Player)
    for k,v in DataStoreLight.DataTable do
        
        local Data1 = PlayerData1[Player.UserId][k]
        local Data2 = PlayerData2[Player.UserId][k]
        DataStoreLight:Debug(Data1 , Data2)

        if Data1 ~= nil then
            if DataStoreLight.Setting.ServerCompress then    
                DataStoreLight:Debug(`Save for {Data1} ...`)

                local Buffer_Data1 = msgpack.utf8Encode(msgpack.encode(Data1))
                local Compress_Data1 = rbxzstd.compress(buffer.fromstring(Buffer_Data1))

                DataStoreLight:Debug(`Data1 : {Compress_Data1}`)
                
                if Compress_Data1 then
                    DataStoreLight:Debug(`압축한 데이터 저장중 : {Data1} ...`)
                    
                    DataStoreLight:waitForRequest(Enum.DataStoreRequestType.SetIncrementAsync)
                    
                    DataStoreService:GetDataStore(`{k}:1`):SetAsync(Player.UserId , `\30{base91.encodeString(Compress_Data1)}`)
                else
                    DataStoreLight:Debug(`압축하지 못한 데이터 저장중 : {Data1} ...`)
                    
                    DataStoreLight:waitForRequest(Enum.DataStoreRequestType.SetIncrementAsync)
                    
                    DataStoreService:GetDataStore(`{k}:1`):SetAsync(Player.UserId , `\20{Buffer_Data1}`)
                end
            else
                DataStoreLight:waitForRequest(Enum.DataStoreRequestType.SetIncrementAsync)
                    
                DataStoreService:GetDataStore(`{k}:1`):SetAsync(Player.UserId , `{Data1}`)
            end
        end
        
        if Data2 ~= nil then
            if DataStoreLight.Setting.ServerCompress then    
                DataStoreLight:Debug(`Save for {Data2} ...`)

                local Buffer_Data2 = msgpack.utf8Encode(msgpack.encode(Data2))
                local Compress_Data2 = rbxzstd.compress(buffer.fromstring(Buffer_Data2))
                
                if Compress_Data2 then
                    DataStoreLight:Debug(`압축한 데이터 저장중 : {Data2} ...`)
                    
                    DataStoreLight:waitForRequest(Enum.DataStoreRequestType.SetIncrementAsync)
                    
                    DataStoreService:GetDataStore(`{k}:2`):SetAsync(Player.UserId , `\30{base91.encodeString(Compress_Data2)}`)
                else
                    DataStoreLight:Debug(`압축하지 못한 데이터 저장중 : {Data2} ...`)
                    
                    DataStoreLight:waitForRequest(Enum.DataStoreRequestType.SetIncrementAsync)
                    
                    DataStoreService:GetDataStore(`{k}:2`):SetAsync(Player.UserId , `\20{Buffer_Data2}`)
                end
            else
                DataStoreLight:waitForRequest(Enum.DataStoreRequestType.SetIncrementAsync)
                    
                DataStoreService:GetDataStore(`{k}:1`):SetAsync(Player.UserId , `{Data2}`)
            end
        end
    end
end

--// 클라이언트 컴프레스판 제작예정
--// DataName 파라미터가 존제한다면 그 데이터를 초기값으로 만약 존제하지 않는다면 모든 데이터를 초기값으로
function DataStoreLight.clearData(Player:Player , DataName:string)
    if DataName then
        if DataStoreLight.DataTable[DataName] then
            if PlayerData1[Player.UserId] then
                if PlayerData1[Player.UserId][DataName] ~= nil then
                    DataStoreLight.set(Player , DataName , DataStoreLight.DataTable[DataName])
                    DataStoreLight.set(Player , DataName , DataStoreLight.DataTable[DataName])
                end
            end
        end
    else
        for k,v in DataStoreLight.DataTable do
            if PlayerData1[Player.UserId] then
                if PlayerData1[Player.UserId][k] ~= nil then
                    DataStoreLight.set(Player , k , v)
                    DataStoreLight.set(Player , k , v)
                end
            end
        end
    end
end

--// 클라이언트 컴프레스판 제작예정
--// DataName 파라미터가 존제하면 그 값만 이전값으로 변경 없다면 모든값을 이전값으로 변경
function DataStoreLight.discardChanges(Player:Player , DataName:string)
    if DataName then
        if DataStoreLight.DataTable[DataName] then
            if PlayerData1[Player.UserId] then
                if PlayerData1[Player.UserId][DataName] ~= nil then
                    PlayerData1[Player.UserId][DataName] = PlayerData2[Player.UserId][DataName]
                    PlayerData2[Player.UserId][DataName] = PlayerBeforeDataInServer[Player.UserId][DataName]
                end
            end
        end
    else
        for k,_ in DataStoreLight.DataTable do
            if PlayerData1[Player.UserId] then
                if PlayerData1[Player.UserId][k] ~= nil then
                    PlayerData1[Player.UserId][k] = PlayerData2[Player.UserId][k]
                    PlayerData2[Player.UserId][k] = PlayerBeforeDataInServer[Player.UserId][k]
                end
            end
        end
    end
end

return DataStoreLight
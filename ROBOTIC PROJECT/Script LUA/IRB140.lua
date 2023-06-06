function sysCall_threadmain()


    -- Definizione per gli Handle del gripper, dell'attachPoint del gripper e del target del manipolatore
    gripperSensor = sim.getObjectHandle("ROBOTIQ_85_attachProxSensor")
    connector = sim.getObjectHandle("ROBOTIQ_85_attachPoint")
    target = sim.getObjectHandle("IRB140_target")



    -- Definisco gli Handle per le posizioni di arrivo dei cuboidi di ogni colore
    local Rosso = sim.getObjectHandle("Red")
    local Verde = sim.getObjectHandle("Green")
    local Blu = sim.getObjectHandle("Blue")
    
   
    -- Variabili ausiliarie per definire se cambiare solo la posizione e se l'oggeto è attaccato al gripper.
    local changePositionOnly = 1
    attachedObject = nil
    

    --Definizione di tre table per salvare i cuboidi rossi, verdi e blu
    redProducts = {}
    greenProducts = {}
    blueProducts = {}
    
    
    -- Definisco gli Handle per i path relativi ad ogni colore più il path di ritorno, il vision sensor e le posizioni di grab e idle
    visionSensor = sim.getObjectHandle("Vision_sensor")
    Ritorno = sim.getObjectHandle("BackPath")
    grabPosition = sim.getObjectHandle("grabPosition")
    idlePosition = sim.getObjectHandle("IdlePosition")
    redPosition = sim.getObjectHandle("RedPos")
    greenPosition = sim.getObjectHandle("GreenPos")
    bluePosition = sim.getObjectHandle("BluePos")
    redPath = sim.getObjectHandle("redPath")
    greenPath = sim.getObjectHandle("greenPath")
    bluePath = sim.getObjectHandle("bluePath")
    
    
    --Ottengo la posizione e orientamento della posizione di grab e di idle relative al frame world.
    grabTarget = sim.getObjectPosition(grabPosition, -1)
    grabOrientation = sim.getObjectOrientation(grabPosition, -1)
    idleTarget = sim.getObjectPosition(idlePosition, -1)
    idleOrientation = sim.getObjectOrientation(idlePosition, -1)
    

    -- Creo delle table per le posizioni, orientamenti e i path relativi ad ogni colore
    colorReleasePositions = { sim.getObjectPosition(redPosition, -1),
                                sim.getObjectPosition(greenPosition, -1),
                                sim.getObjectPosition(bluePosition, -1)}
    colorReleaseOrientations = { sim.getObjectOrientation(redPosition, -1),
                                sim.getObjectOrientation(greenPosition, -1),
                                sim.getObjectOrientation(bluePosition, -1)}
    colorPathPositions = { sim.getObjectPosition(redPath, -1),
                                sim.getObjectPosition(greenPath, -1),
                                sim.getObjectPosition(bluePath, -1)}
    colorPathOrientations = { sim.getObjectOrientation(redPath, -1),
                                sim.getObjectOrientation(greenPath, -1),
                                sim.getObjectOrientation(bluePath, -1)}
                                
                
                                
    -- Tramite la funzione changeTarget() imposto la posizione e orientamento del target del manipolatore nella posizione di idle, in questo modo tutto il manipolatore verrà mosso tramite cinematica inversa
    changeTarget(idleTarget, idleOrientation)
    


    -- Loop while per far eseguire la task determinata al manipolatore
    while (true) do
        -- Salvo il valore acquisito dal vision sensor e salvo i valori relativi a red, blue e green nelle relative variabili.
        imageBuffer = sim.getVisionSensorCharImage(visionSensor, 0, 0, 1, 1)
        red = tonumber(string.byte(imageBuffer, 1))
        green = tonumber(string.byte(imageBuffer, 2))
        blue = tonumber(string.byte(imageBuffer, 3))
        

        -- Costrutto if-else per determinare le posizioni di arrivo, e il path da far eseguire al manipolatore
        if (red~= 0 and green~=0 and blue~=0) then
            targetPosition = {}
            targetOrientation = {}
            targetPathPosition = {}
            targetPathOrientation = {}
            


            if ( red > green and red> blue) then
                --Imposto il path di andata a Rosso, e chiamo la funzione updatePosition() con parametro 1, che indica è stato rilevato un cuboide rosso.
                Andata = Rosso
                i = 1
                updatePosition(i)
                -- Sposto la posizione del path e del target di 0.1 in meno sull'asse x, in modo da far sì che il manipolatore lasci il cuboide dietro l'ultimo posizionato
                targetPosition[1] = targetPosition[1] - (0.1* getLength(redProducts))
                targetPathPosition[1] = targetPathPosition[1] - (0.1 * getLength(redProducts))
                cuboidColor = "red"
                

            elseif ( green > red and green > blue) then
                Andata = Verde
                i = 2
                updatePosition(i)
                targetPosition[1] = targetPosition[1] - (0.1* getLength(greenProducts))
                targetPathPosition[1] = targetPathPosition[1] - (0.1 * getLength(greenProducts))
                cuboidColor = "green"                                    
                                    

            elseif ( blue > red and blue > green ) then
                Andata = Blu
                i = 3
                updatePosition(i)
                targetPosition[1] = targetPosition[1] - (0.1* getLength(blueProducts))
                targetPathPosition[1] = targetPathPosition[1] - (0.1 * getLength(blueProducts))
                cuboidColor = "blue"
                                    
            end
            

            
            --Semplice sequenza di posizioni che permette di eseguire la task desiderata
            changeTarget(grabTarget, grabOrientation)
            sim.wait(1)
            -- Tramite la funzione grabCuboid() attacco il cuboide al gripper
            grabCuboid(cuboidColor)
            sim.wait(0.5)
            sim.followPath(target, Andata, changePositionOnly, 0, 0.7,15)
            sim.wait(1)
 
            changeTarget(targetPosition, targetOrientation)
            sim.wait(1)

            -- Tramite la funzione dropCuboid() stacco il cuboide dal gripper
            dropCuboid()
            sim.wait(1)
            changeTarget(targetPathPosition, targetPathOrientation)
            sim.wait(0.5)

            sim.followPath(target, Ritorno, changePositionOnly, 0, 0.7,15)
            sim.wait(1)
            

            -- Chiamo la funzione clearTables() per simulare l'azione dell'operatore umano, nel caso in cui ci siano più di 2 cuboidi dello stesso colore
            clearTables()
        end
        
    
    
    end
    
end

function sysCall_cleanup()
    -- Put some clean-up code here
end


function changeTarget(position, orientation)
    -- Funzione per spostare il target del IRB140, in questo modo tutto il manipolatore si muoverà per far raggiungere all'end effector la posizione e orientamento desiderati
    sim.setObjectPosition(target, -1, position)
    sim.setObjectOrientation(target, -1, orientation)

end


function grabCuboid (color)
    
    index = 0
    -- Ciclo while per attaccare il cuboide al gripper
    while (true) do
        -- Tramite la funzione sim.getObjects() recupero gli handle delle shape che stanno venendo generate
        objectInScene = sim.getObjects(index, sim.object_shape_type)
        
        --Se sim.getObjects() restituisce -1 se non viene individuato nessun oggetto, in questo caso si esce dal ciclo
        if (objectInScene == -1) then break end
        
        -- Tramite l'handle dello shape recuperato in precedenza ottengo il nome dello stesso e verifico che i primi 6 caratteri siano "cuboid"
        objectName = sim.getObjectName(objectInScene)
        isCuboid = "Cuboid" == string.sub(objectName, 1, 6)


        -- Nel caso che l'oggetto gestito sia un cuboid, che sia respondable e che il sensore di prossimità del gripper abbia rilevato l'oggetto, posso proseguire ad attaccarlo al gripper
        if ((isCuboid) and 
                (sim.getObjectInt32Parameter(objectInScene, sim.shapeintparam_respondable) ~= 0) and
                (sim.checkProximitySensor(gripperSensor, objectInScene) == 1 )  ) then
            

                -- Imposto l'oggetto come attachedObject e imposto il sua "parent" al connector, ovvero l'attachPoint del gripper
                attachedObject = objectInScene
                sim.setObjectParent(objectInScene, connector, true)

                -- Inseriesco nella relativa table l'oggetto appena gestito
                if ( color == "red" ) then
                    table.insert(redProducts, objectInScene)
                elseif ( color == "green" ) then
                    table.insert(greenProducts, objectInScene)
                else
                    table.insert(blueProducts, objectInScene)
                end
                
                break
        end
    index = index + 1
    end


end


function dropCuboid()
    -- Disaccoppio l'oggetto dal parent (il connector del gripper) in modo da farlo scollegare.
    sim.setObjectParent(objectInScene, -1, true)
end


function getLength(t)
    
    count = 0
    -- ciclo for che conta quanti elementi sono presenti in una delle tre table redProducts, greenProducts o greenProducts e ne restituisce la somma
    for index,values in pairs(t) do
        count = count + 1
    end
    
    return count
    
end


function clearTables()
    
    redCount = getLength(redProducts)
    greenCount = getLength(greenProducts)
    blueCount = getLength(blueProducts)
    

    --[[ 
    Tramite la funzione getLength calcolo quanti cuboidi di un determinato colore sono presenti, 
    nel caso in cui ce ne siano 2 o più vengono rimossi dalla scena, per simulare l'azione dell'operatore umano --]]
    if (redCount >= 2) then
        for index, value in pairs(redProducts) do
            sim.removeObject(redProducts[index])
        end
        redProducts = {}
    end

    if (greenCount >= 2) then
        for index, value in pairs(greenProducts) do
            sim.removeObject(greenProducts[index])
        end
        greenProducts = {}
    end
    
    
    if (blueCount >= 2) then
        for index, value in pairs(blueProducts) do
            sim.removeObject(blueProducts[index])
        end
        blueProducts = {}
    end
end


function updatePosition(i)


    --Funzione per aggiornare la posizione, orientamento, path e orientamento durante il path per il colore definito.
    local Element = colorReleasePositions[i]

    for _, value in pairs(Element) do
        table.insert(targetPosition, value)
    end

    
    local Element = colorReleaseOrientations[i]

    for _, value in pairs(Element) do
        table.insert(targetOrientation, value)
    end

    
    local Element = colorPathPositions[i]

    for _, value in pairs(Element) do
        table.insert(targetPathPosition, value)
    end

    
    local Element = colorPathOrientations[i]

    for _, value in pairs(Element) do
        table.insert(targetPathOrientation, value)
    end



end

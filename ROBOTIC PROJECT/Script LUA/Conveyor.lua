function sysCall_init() 
    pathHandle=sim.getObjectHandle("ConveyorBeltPath")
    forwarder=sim.getObjectHandle('ConveyorBelt_forwarder')
    sim.setPathTargetNominalVelocity(pathHandle,0) -- for backward compatibility
    
    
    -- Salvo sulla variable visionSensor l'handle del vision sensor per poter acquisire informazioni
    visionSensor = sim.getObjectHandle("Vision_sensor")
end

function sysCall_actuation()
    -- Con la funzione sim.getVisionSensorCharImage() ottengo i valori RGB del vision sensor.
    imageBuffer = sim.getVisionSensorCharImage(visionSensor, 0, 0, 1, 1)
    

    -- Converto i valori acquisiti dal vision sensor in numeri e li salvo su tre variabili diverse.
    red = tonumber(string.byte(imageBuffer, 1))
    green = tonumber(string.byte(imageBuffer, 2))
    blue = tonumber(string.byte(imageBuffer, 3))
    
    -- Imposto la velocità del conveyor belt a zero
    local beltVelocity = nil
    

    -- Semplice costrutto if-else per far muovere il conveyor belt solo se il sensore non vede nulla, quindi se non c'è un cuboide alla fine dello stesso.
    if (red ~= 0 and green ~=0 and blue ~= 0) then
        beltVelocity = 0
    else
        beltVelocity=sim.getScriptSimulationParameter(sim.handle_self,"conveyorBeltVelocity")
    end

    local dt=sim.getSimulationTimeStep()
    local pos=sim.getPathPosition(pathHandle)
    pos=pos+beltVelocity*dt
    sim.setPathPosition(pathHandle,pos) -- update the path's intrinsic position
    
    
    -- Here we "fake" the transportation pads with a single static rectangle that we dynamically reset
    -- at each simulation pass (while not forgetting to set its initial velocity vector) :
    
    local relativeLinearVelocity={beltVelocity,0,0}
    -- Reset the dynamic rectangle from the simulation (it will be removed and added again)
    sim.resetDynamicObject(forwarder)
    -- Compute the absolute velocity vector:
    local m=sim.getObjectMatrix(forwarder,-1)
    m[4]=0 -- Make sure the translation component is discarded
    m[8]=0 -- Make sure the translation component is discarded
    m[12]=0 -- Make sure the translation component is discarded
    local absoluteLinearVelocity=sim.multiplyVector(m,relativeLinearVelocity)
    -- Now set the initial velocity of the dynamic rectangle:
    sim.setObjectFloatParameter(forwarder,sim.shapefloatparam_init_velocity_x,absoluteLinearVelocity[1])
    sim.setObjectFloatParameter(forwarder,sim.shapefloatparam_init_velocity_y,absoluteLinearVelocity[2])
    sim.setObjectFloatParameter(forwarder,sim.shapefloatparam_init_velocity_z,absoluteLinearVelocity[3])
end 

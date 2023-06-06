function sysCall_threadmain()
   
    -- Salvo sulla variable gen l'handle del dummy utilizzato per definire la posizione dove verranno generati i cuboidi
    gen = sim.getObjectHandle("Generazione")
    -- Prendo la posizione del dummy rispetto alle coordinate assolute (world)
    Position = sim.getObjectPosition(gen,-1)
    
    
    
    --[[ 
    Definisco una table "colors" con all'interno i valori RGB per indicare Rosso, Verde e Blu.
    Successivamente imposto currentColor al primo valore della table, in questo caso una tonalità di rosso.
     ]]--
    colors = { {0.9, 0.5, 0.5}, {0.5, 0.9, 0.5}, {0.5, 0.5, 0.9} }
    currentColor = colors[1]
    
    -- Creo un loop while che verrà eseguito all'infinito
    while(true) do
        -- Chiamo la funzione changeColor() per impostare currentColor ad un colore casuale tra quelli definiti in precedenza
        currentColor = changeColor()
        --[[ 
        Utilizzo la funzione sim.createPureShape() per creare un cuboide, gli argomenti della funzione sono:
        primitiveType = 0 per indicare cuboide;
        options = è un parametro codificato a bit, in questo caso sono settati solo i primi 3 bit, quindi il cuboide sarà respondable, con i bordi visibili e smooth;
        sizes = una table per indicare le dimensioni {0.05,0.05,0.05};
        mass = la massa del cuboide;
        precision = due valori per indicare le facce di una sfera o cilindro, possono essere lasciati a nil (NULL) nel nostro caso.
        ]]--
        cuboid = sim.createPureShape(0, 15, {0.05,0.05,0.05}, 0.2, nil)

        
        --[[
        La funzione sim.setObjectInt32Parameter() permette di impostare un parametro della shape.
        Il parametro 3003 corrisponde alla proprietà "static", in questo caso viene settato a 0, quindi la shape è dinamica, 
        questo implica che la sua posizione e orientamento vengono influenzati durante una simulazione
        ]]--
        sim.setObjectInt32Parameter(cuboid, 3003, 0) 
        --Il parametro 3004 corrisponde alla proprietà "respondable", che implica che il cuboide "toccherà" altre shapes se le loro respondable masks sono uguali.
        sim.setObjectInt32Parameter(cuboid, 3004, 1) 
        --Con la funzione sim.setObjectSpecialProperty() viene settata la proprietà renderable in modo da rendere il cuboide visibile dal vision sensor 
        sim.setObjectSpecialProperty(cuboid, sim.objectspecialproperty_renderable) 
        --Imposto il colre della shape a quello definito dalla funzione changeColor(), il secondo parametro è per inserire il nome di un colore già definito, il terzo se si vuole usare una componente 
        sim.setShapeColor(cuboid, nil, sim.colorcomponent_ambient, currentColor) 
        
        -- Tramite la funzione sim.setObjectParent() indico che la shape appena creata è "parentless" (-1) e con l'ultimo parametro indico che deve mantenere la posizione e orientamento assegnati
        sim.setObjectParent(cuboid, -1, true)
        -- Tramite la funzione sim.setObjectPosition() setto la posizione del cuboide a quella del dummy definito all'inzio, il parametro -1 indica che il frame di riferimento è world.
        sim.setObjectPosition(cuboid, -1, Position)
        -- Aspetto 10 secondi per generare il prossimo cuboide
        sim.wait(10)
    
    end
    
    
end

function sysCall_cleanup()

end


function changeColor()
    -- Banale if else per scegliere un colore tra i tre possibili
    randomNumber = sim.getRandom()
    if (randomNumber < 0.33) then
        return colors[1]
    elseif (randomNumber >= 0.33 and randomNumber <0.67) then
        return colors[2]
    else

    return colors[3]
    end
end


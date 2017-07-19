module DatabaseHandling
  import MessengerAnalyze

  using SQLite

  mutable struct Database<:MessengerAnalyze.Database
    db::SQLite.DB
    dbName::String
    function Database(name::String)
      new(SQLite.DB(),name)
    end
  end
  abstract type AbstractEntry end
  mutable struct Message<:AbstractEntry
    id::Int64
    senderName::String
    sendeeName::String
    timeMessage::Real
    messageText::String
    multiMedia::Integer
  end
  function Database(config)
    Database(config["database-name"])
  end
  function setUp(database::Database)
    try mkdir("database") end
    database.db=SQLite.DB("database/"*database.dbName)
    attemptTransaction(database) do db
      tableString="
      CREATE TABLE IF NOT EXISTS MessageTable
      (
      id Integer primary key,
      senderName String,
      sendeeName String,
      timeMessage Real,
      messageText String,
      multiMedia Integer
      )
      "
      SQLite.execute!(db,tableString )
    end
  end
  function tableNameFromType{entryType<:AbstractEntry}(::Type{entryType})
    split(string(entryType),".")[end]*"Table"
  end
  function valuesFromEntry(entry::AbstractEntry)
    map(field->getfield(entry,field),fieldnames(typeof(entry))[2:end])
  end
  function namesOfEntry{entryType<:AbstractEntry}(::Type{entryType})
    mapreduce(string,(l,r)->l*","*r,fieldnames(entryType)[2:end])
  end
  function entryPositions{entryType<:AbstractEntry}(::Type{entryType})
    mapreduce(idx->"?"*string(idx),(l,r)->l*","*r,1:(length(fieldnames(entryType))-1))
  end
  function writeDB(database::Database,entry::AbstractEntry)
    tableName=tableNameFromType(typeof(entry))
    columnNames=namesOfEntry(typeof(entry))
    entries=entryPositions(typeof(entry))
    attemptTransaction(database) do db
      SQLite.query(db,"INSERT INTO $(tableName)($(columnNames)) VALUES ($(entries)) ",values=valuesFromEntry(entry))
    end
  end

  function getSQLiteSource(database::Database,::Type{entryType}) where entryType<:AbstractEntry
    tableName=tableNameFromType(entryType)
    SQLite.Source(database.db, "SELECT * FROM $(tableName)")
  end


  function attemptTransaction(databaseFunction::Function,database::Database)
    try
      SQLite.execute!(database.db, "BEGIN; ")
      databaseFunction(database.db)
    catch
      SQLite.execute!(database.db, "ROLLBACK; ")
      rethrow()
    finally
      SQLite.execute!(database.db, "COMMIT; ")
    end
  end
end

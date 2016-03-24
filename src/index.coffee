AbstractClientStore = require('express-brute/lib/AbstractClientStore')
moment = require('moment')
#_ = require('underscore')
#Waterline = require('waterline')

bruteStore = module.exports = () ->
  AbstractClientStore.apply(this, arguments)
  options = {
    logging:
      true
  }
  this.options = _.extend({}, bruteStore.defaults, options)

  return this

###
bruteStore = module.exports = (callback) ->
  AbstractClientStore.apply(this, arguments)
  options = {
    logging:
      true
    adapters:
      'mysql': sailsMemoryAdapter

    connections:
      default:
        adapter: 'memory'
  }
  this.options = _.extend({}, bruteStore.defaults, options)
  self = this
  self.bruteforceCollection = waterline.Collection.extend({
    identity: 'bruteforce'
    _id:
      type: 'string'
      unique: true
    expires:
      type: 'datetime'
    firstRequest:
      type: 'datetime'
    lastRequest:
      type: 'datetime'
    count:
      type: 'datetime'
    autoPK: false
    autoCreatedAt: false
    autoUpdatedAt: false
  })

  waterline.loadCollection(self.bruteforceCollection)

  waterline.initialize(options, (err, ontology) ->

    if err
      if self.options.logging
        console.log "Failed to initialize bruteStore - table #{table}"
      return callback(self)
    if self.options.logging
      console.log "bruteStore initialized - table #{table} created"
    callback(self)
  )
###
bruteStore.prototype = Object.create(AbstractClientStore.prototype)

bruteStore.prototype.set = (key, value, lifetime, callback) ->
  _id = this.options.prefix+key
  expiration = if lifetime then moment().add(lifetime, 'seconds').toDate() else null

  #Bruteforce = Waterline.collections.bruteforce
  Bruteforce.find
    where:
      _id: _id
  .exec (err, doc) ->
    if err and callback
      return callback(err)

    if doc
      doc._id = _id
      doc.count = value.count
      doc.lastRequest = value.lastRequest
      doc.firstRequest = value.firstRequest
      doc.expires = expiration
      doc.save (err) ->
        callback() if callback and not err
        callback(err) if callback and err

    else
      Bruteforce.create
        _id: _id
        count: value.count
        lastRequest: value.lastRequest
        firstRequest: value.firstRequest
        expires: expiration
      .exec (err, doc) ->
        callback() if callback and not err
        callback(err) if callback and err

bruteStore.prototype.get = (key, callback) ->
  #self = this
  _id = this.options.prefix+key
  #Bruteforce = Waterline.collections.bruteforce
  Bruteforce.find
    where:
      _id: _id
  .exec (err, doc) ->
    typeof callback == 'function' &&  callback(err, null) if err
    data = {}
    if doc && new Date(doc.expires).getTime() < new Date().getTime()
      Bruteforce.destroy
        _id: _id
      .exec (err) ->
        return callback(err) if err
        return callback() if not err
    if doc
      data.count = doc.count
      data.lastRequest = new Date(doc.lastRequest)
      data.firstRequest = new Date(doc.firstRequest)
      typeof callback == 'function' && callback(null, data)
    else
      typeof callback == 'function' && callback(null, null)

bruteStore.prototype.reset = (key, callback) ->
  self = this
  _id = this.options.prefix+key
  Bruteforce = Waterline.collections.bruteforce
  Bruteforce.destroy
    _id: _id
  .exec (err, doc) ->
    typeof callback == 'function' && callback(err, null) if err
    typeof callback == 'function' && callback(null, doc) if not err

bruteStore.defaults = {
  prefix: ''
  logging: false
}
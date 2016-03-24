expect = require('expect.js')
Waterline = require('waterline')
sailsMemoryAdapter = require('sails-memory')
###
sequelize = new Sequelize('sequelizeBrute-test', 'root', 'new-password', {
  host: "127.0.0.1"
  dialect: "mysql"
  logging: false
})
###
waterline = new Waterline()

WaterlineStore = require('../')

describe 'MemoryStore', ->
  waterlineStore = null
  beforeEach (done) ->
    this.timeout(5000)
    new WaterlineStore(waterline, 'bruteforce', {
      logging:
        true
      adapters:
        'memory': sailsMemoryAdapter

      connections:
        default:
          adapter: 'memory'
    }, (store) ->
      waterlineStore = store
      done()
    )

  it 'should be able to set a value', (done) ->
    waterlineStore.set('foo', {count:123}, 1000, (err) ->
      return done(err) if err
      Bruteforce = Waterline.collections.bruteforce
      Bruteforce.find
        where:
          _id: 'foo'
      .exec (err, doc) ->
        return done(err) if err
        expect(doc.count).to.be(123)
        expect(doc.expires).to.be.a(Date)
        done()

    )

  it 'should be able to get a value', (done) ->
    waterlineStore.set('foo', {count:123}, 1000, (err) ->
      return done(err) if err
      waterlineStore.get 'foo', (err, doc) ->
        return done(err) if err
        expect(doc).have.property('count')
        expect(doc.count).to.be(123)
        done()
    )

  it 'should return undefined if expired', (done) ->
    waterlineStore.set('foo', {count:123}, 0, (err) ->
      return done(err) if err
      setTimeout ->
          waterlineStore.get 'foo', (err, doc) ->
            expect(doc).to.be(undefined)
            done()
      , 200
    )



  it 'should delete the doc if expired', (done) ->
    waterlineStore.set('foo', {count:123}, 0, (err) ->
      return done(err) if err
      setTimeout ->
          waterlineStore.get 'foo', (err, doc) ->
            setTimeout ->
                Bruteforce = Waterline.collections.bruteforce
                Bruteforce.find
                  where:
                    _id: 'foo'
                .exec (err, doc) ->
                  return done(err) if err
                  expect(doc).to.be(null)
                  done()
            , 100
            done()
      , 100
    )

  it 'should be able to reset', (done) ->
    waterlineStore.set('foo', {count:123}, 1000, (err) ->
      return done(err) if err
      waterlineStore.reset 'foo', (err, doc) ->
        return done(err) if err
        Bruteforce = Waterline.collections.bruteforce
        Bruteforce.find
          where:
            _id: 'foo'
        .exec (err, doc) ->
          return done(err) if err
          expect(doc).to.be(null)
          done()
    )
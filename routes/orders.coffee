Order = require "../models/order"
Wallet = require "../models/wallet"
JsonRenderer = require "../lib/json_renderer"

module.exports = (app)->

  app.post "/orders", (req, res)->
    if req.user
      data = req.body
      data.user_id = req.user.id
      Wallet.findUserWalletByCurrency req.user.id, data.buy_currency, (err, buyWallet)->
        return JsonRenderer.error "Wallet #{data.buy_currency} does not exist.", res  if err or not buyWallet
        Wallet.findUserWalletByCurrency req.user.id, data.sell_currency, (err, wallet)->
          return JsonRenderer.error "Wallet #{data.sell_currency} does not exist.", res  if err or not wallet
          wallet.holdBalance parseFloat(data.amount), (err, wallet)->
            return JsonRenderer.error "Not enough #{data.sell_currency} to open an order.", res  if err or not wallet
            Order.create data, (err, order)->
              return JsonRenderer.error "Sorry, could not open an order...", res  if err
              res.json JsonRenderer.order order
    else
      JsonRenderer.error "Please auth.", res

  app.get "/orders", (req, res)->
    Order.findByOptions req.query, (err, orders)->
      return JsonRenderer.error "Sorry, could not get open orders...", res  if err
      res.json JsonRenderer.orders orders

  app.del "/orders/:id", (req, res)->
    if req.user
      Order.findOne {user_id: req.user.id, _id: req.params.id}, (err, order)->
        return JsonRenderer.error "Sorry, could not delete orders...", res  if err or not order
        Wallet.findUserWalletByCurrency req.user.id, order.sell_currency, (err, wallet)->
          wallet.holdBalance -order.amount, (err, wallet)->
            order.remove ()->
              res.json JsonRenderer.orders order
    else
      JsonRenderer.error "Please auth.", res
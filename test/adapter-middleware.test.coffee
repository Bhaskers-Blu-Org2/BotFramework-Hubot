chai = require 'chai'
expect = chai.expect
{ TextMessage, Message, User } = require 'hubot'
MockRobot = require './mock-robot'
{ BaseMiddleware, TextMiddleware, middlewareFor } = require '../src/adapter-middleware'
BotBuilderTeams = require('./mock-botbuilder-teams')

describe 'middlewareFor', ->
    it 'should return Middleware for null', ->
        middleware = middlewareFor(null)
        expect(middleware).to.be.not.null

    it 'should return Middleware for any string', ->
        middleware = middlewareFor("null")
        expect(middleware).to.be.not.null

    it 'should return Middleware for proper channel', ->
        middleware = middlewareFor("msteams")
        expect(middleware).to.be.not.null
        

describe 'BaseMiddleware', ->
    describe 'toReceivable', ->
        robot = null
        event = null
        beforeEach ->
            robot = new MockRobot
            event =
                type: 'message'
                text: 'Bot do something and tell User about it'
                agent: 'tests'
                source: '*'
                address:
                    conversation:
                        id: "conversation-id"
                    bot:
                        id: "bot-id"
                    user:
                        id: "user-id"
                        name: "user-name"

        it 'should throw', ->
            middleware = new BaseMiddleware(robot)
            expect(() ->
                middleware.toReceivable(event)
            ).to.throw()

    describe 'toSendable', ->
        robot = null
        message = null
        context = null
        beforeEach ->
            robot = new MockRobot
            context =
                user:
                    id: 'user-id'
                    name: 'user-name'
                    activity:
                        type: 'message'
                        text: 'Bot do something and tell User about it'
                        agent: 'tests'
                        source: '*'
                        address:
                            conversation:
                                id: "conversation-id"
                            bot:
                                id: "bot-id"
                            user:
                                id: "user-id"
                                name: "user-name"
            message = "message"

        it 'should throw', ->
            middleware = new BaseMiddleware(robot)
            expect(() ->
                middleware.toSendable(context, message)
            ).to.throw()

describe 'TextMiddleware', ->
    describe 'toReceivable', ->
        robot = null
        event = null
        beforeEach ->
            robot = new MockRobot
            event =
                type: 'message'
                text: 'Bot do something and tell User about it'
                agent: 'tests'
                source: '*'
                address:
                    conversation:
                        id: "conversation-id"
                    bot:
                        id: "bot-id"
                    user:
                        id: "user-id"
                        name: "user-name"

        it 'return generic message when appropriate type is not found', ->
            # Setup
            event.type = 'typing'
            middleware = new TextMiddleware(robot)

            # Action
            receivable = null
            expect(() ->
                receivable = middleware.toReceivable(event)
            ).to.not.throw()

            # Assert
            expect(receivable).to.be.not.null

        it 'return message when type is message', ->
            # Setup
            middleware = new TextMiddleware(robot)

            # Action
            receivable = null
            expect(() ->
                receivable = middleware.toReceivable(event)
            ).to.not.throw()

            # Assert
            expect(receivable).to.be.not.null

    describe 'toSendable', ->
        robot = null
        message = null
        context = null
        beforeEach ->
            robot = new MockRobot
            context =
                user:
                    id: 'user-id'
                    name: 'user-name'
                    activity:
                        type: 'message'
                        text: 'Bot do something and tell User about it'
                        agent: 'tests'
                        source: '*'
                        address:
                            conversation:
                                id: "conversation-id"
                            bot:
                                id: "bot-id"
                            user:
                                id: "user-id"
                                name: "user-name"
            message = "message"

        it 'should create message object for string messages', ->
            # Setup
            middleware = new TextMiddleware(robot)

            # Action
            sendable = null
            expect(() ->
                sendable = middleware.toSendable(context, message)
            ).to.not.throw()

            # Verify
            expected = {
                type: 'message'
                text: message
                address: context.user.activity.address
            }
            expect(sendable).to.deep.equal(expected)

        it 'should not alter non-string messages', ->
            # Setup
            message =
              type: "some message type"
            middleware = new TextMiddleware(robot)

            # Action
            sendable = null
            expect(() ->
                sendable = middleware.toSendable(context, message)
            ).to.not.throw()

            # Verify
            expected = message
            expect(sendable).to.deep.equal(expected)

    describe 'supportsAuth', ->
        it 'should return false', ->
            # Setup
            robot = new MockRobot
            middleware = new TextMiddleware(robot)

            # Action and Assert
            expect(middleware.supportsAuth()).to.be.false
    
    describe 'constructErrorResponse', ->
        it 'return a proper payload with the text of the error', ->
            # Setup
            robot = new MockRobot
            middleware = new TextMiddleware(robot)
            event =
                type: 'message'
                text: 'Bot do something and tell User about it'
                agent: 'tests'
                source: '*'
                address:
                    conversation:
                        id: "conversation-id"
                    bot:
                        id: "bot-id"
                    user:
                        id: "user-id"
                        name: "user-name"

            # Action
            result = null
            expect(() ->
                result = middleware.constructErrorResponse(event, "an error message")
            ).to.not.throw()

            # Assert
            expect(result).to.eql {
                type: 'message'
                text: 'an error message'
                address:
                    conversation:
                            id: "conversation-id"
                        bot:
                            id: "bot-id"
                        user:
                            id: "user-id"
                            name: "user-name"
            }
    
    describe 'send', ->
        robot = null
        middleware = null
        connector = null
        payload = null
        cb = () -> {}

        beforeEach ->
            robot = new MockRobot
            middleware = new TextMiddleware(robot)
            connector = new BotBuilderTeams.TeamsChatConnector({
                appId: 'a-app-id'
                appPassword: 'a-app-password'
            })
            connector.send = (payload, cb) ->
                robot.brain.set("payload", payload)

            payload = {
                type: 'message'
                text: ""
                address:
                    conversation:
                        isGroup: 'true'
                        conversationType: 'channel'
                        id: "19:conversation-id"
                    bot:
                        id: 'a-app-id'
                    user:
                        id: "user-id"
                        name: "user-name"
            }

        it 'should package non-array payload in array before sending', ->
            # Setup
            expected = [{
                type: 'message'
                text: ""
                address:
                    conversation:
                        isGroup: 'true'
                        conversationType: 'channel'
                        id: "19:conversation-id"
                    bot:
                        id: 'a-app-id'
                    user:
                        id: "user-id"
                        name: "user-name"
            }]

            # Action
            expect(() ->
                middleware.send(connector, payload)
            ).to.not.throw()

            # Assert
            result = robot.brain.get("payload")
            expect(result).to.deep.eql(expected)


        it 'should pass payload array through unchanged', ->
            # Setup
            payload = [payload]
            expected = [{
                type: 'message'
                text: ""
                address:
                    conversation:
                        isGroup: 'true'
                        conversationType: 'channel'
                        id: "19:conversation-id"
                    bot:
                        id: 'a-app-id'
                    user:
                        id: "user-id"
                        name: "user-name"
            }]

            # Action
            expect(() ->
                middleware.send(connector, payload)
            ).to.not.throw()

            # Assert
            result = robot.brain.get("payload")
            expect(result).to.deep.eql(expected)

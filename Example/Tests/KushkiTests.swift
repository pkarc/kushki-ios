import XCTest
import OHHTTPStubs
@testable import Kushki

class KushkiTests: XCTestCase {

    var publicMerchantId: String?
    var totalAmount: Double?

    override func setUp() {
        super.setUp()
        publicMerchantId = "10000001436354684173102102"
        totalAmount = 10.0
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testReturnsTokenWhenCalledWithValidParams() {
        let asyncExpectation = expectation(description: "requestToken")
        let card = Card(name: "John Doe", number: "4242424242424242", cvv: "123", expiryMonth: "12", expiryYear: "21")
        let expectedToken = Helpers.randomAlphanumeric(32)
        let expectedRequestMessage = buildRequestMessage(withMerchantId: publicMerchantId!, withCard: card, withAmount: totalAmount!)
        let expectedRequestBody = expectedRequestMessage
        let kushki = Kushki(publicMerchantId: publicMerchantId!,
                            currency: "USD",
                            environment: KushkiEnvironment.testing)
        _ = stub(condition: isHost("api-uat.kushkipagos.com")
            && isPath("/v1/tokens")
            && isMethodPOST()) { request in
                let nsUrlRequest = request as NSURLRequest
                let requestBody = String(data: nsUrlRequest.ohhttpStubs_HTTPBody(), encoding: .utf8)
                XCTAssertEqual(expectedRequestBody, requestBody)
                let responseBody = [
                    "token": expectedToken
                ]
                return OHHTTPStubsResponse(jsonObject: responseBody, statusCode: 200, headers: nil)
        }
        var transaction = Transaction(code: "", message: "", token: "")
        kushki.requestToken(card: card, totalAmount: totalAmount!) { returnedTransaction in
            transaction = returnedTransaction
            asyncExpectation.fulfill()
        }
        self.waitForExpectations(timeout: 1) { error in
            XCTAssertEqual(expectedToken, transaction.token)
            XCTAssertTrue(transaction.isSuccessful())
        }
    }
    
    func testReturnsSubscriptionTokenWhenCalledWithValidParams() {
        let asyncExpectation = expectation(description: "requestSubscriptionToken")
        let card = Card(name: "John Doe", number: "4242424242424242", cvv: "123", expiryMonth: "12", expiryYear: "21")
        let expectedToken = Helpers.randomAlphanumeric(32)
        let expectedRequestMessage = buildRequestMessageWithoutAmount(withMerchantId: publicMerchantId!, withCard: card)
        let expectedRequestBody = expectedRequestMessage
        let kushki = Kushki(publicMerchantId: publicMerchantId!,
                            currency: "USD",
                            environment: KushkiEnvironment.testing)
        _ = stub(condition: isHost("api-uat.kushkipagos.com")
            && isPath("/v1/subscription-tokens")
            && isMethodPOST()) { request in
                let nsUrlRequest = request as NSURLRequest
                let requestBody = String(data: nsUrlRequest.ohhttpStubs_HTTPBody(), encoding: .utf8)
                XCTAssertEqual(expectedRequestBody, requestBody)
                let responseBody = [
                    "token": expectedToken
                ]
                return OHHTTPStubsResponse(jsonObject: responseBody, statusCode: 200, headers: nil)
        }
        var transaction = Transaction(code: "", message: "", token: "")
        kushki.requestSubscriptionToken(card: card) { returnedTransaction in
            transaction = returnedTransaction
            asyncExpectation.fulfill()
        }
        self.waitForExpectations(timeout: 1) { error in
            XCTAssertEqual(expectedToken, transaction.token)
            XCTAssertTrue(transaction.isSuccessful())
        }
    }

    func testDoesNotReturnTokenWhenCalledWithInvalidParams() {
        let asyncExpectation = expectation(description: "requestToken")
        let card = Card(name: "Invalid John Doe", number: "000000", cvv: "123", expiryMonth: "12", expiryYear: "21")
        let expectedRequestMessage = buildRequestMessage(withMerchantId: publicMerchantId!, withCard: card, withAmount: totalAmount!)
        let expectedRequestBody = expectedRequestMessage
        let kushki = Kushki(publicMerchantId: publicMerchantId!,
                            currency: "USD",
                            environment: KushkiEnvironment.testing)
        _ = stub(condition: isHost("api-uat.kushkipagos.com")
            && isPath("/v1/tokens")
            && isMethodPOST()) { request in
                let nsUrlRequest = request as NSURLRequest
                let requestBody = String(data: nsUrlRequest.ohhttpStubs_HTTPBody(), encoding: .utf8)
                XCTAssertEqual(expectedRequestBody, requestBody)
                let responseBody = [
                    "code": "017",
                    "message": "Tarjeta no válida"
                ]
                return OHHTTPStubsResponse(jsonObject: responseBody, statusCode: 402, headers: nil)
        }
        var transaction = Transaction(code: "", message: "", token: "")
        kushki.requestToken(card: card, totalAmount: totalAmount!) { returnedTransaction in
            transaction = returnedTransaction
            asyncExpectation.fulfill()
        }
        self.waitForExpectations(timeout: 1) { error in
            XCTAssertEqual("017", transaction.code)
            XCTAssertEqual("Tarjeta no válida", transaction.message)
            XCTAssertEqual("", transaction.token)
            XCTAssertFalse(transaction.isSuccessful())
        }
    }
    
    
    private func buildRequestMessage(withMerchantId publicMerchantId: String, withCard card: Card, withAmount totalAmount: Double) -> String {
        let requestDictionary:[String : Any] = [
            "card": [
                "name": card.name,
                "number": card.number,
                "expiryMonth": card.expiryMonth,
                "expiryYear": card.expiryYear,
                "cvv": card.cvv
            ],
            "totalAmount": totalAmount,
            "currency": "USD"
        ]
        let jsonData = try! JSONSerialization.data(withJSONObject: requestDictionary, options: .prettyPrinted)
        let dictFromJson = String(data: jsonData, encoding: String.Encoding.ascii)
        return dictFromJson!
    }
    
    private func buildRequestMessageWithoutAmount(withMerchantId publicMerchantId: String, withCard card: Card) -> String {
        let requestDictionary:[String : Any] = [
            "card": [
                "name": card.name,
                "number": card.number,
                "expiryMonth": card.expiryMonth,
                "expiryYear": card.expiryYear,
                "cvv": card.cvv
            ],
            "currency": "USD"
        ]
        let jsonData = try! JSONSerialization.data(withJSONObject: requestDictionary, options: .prettyPrinted)
        let dictFromJson = String(data: jsonData, encoding: String.Encoding.ascii)
        return dictFromJson!
    }
}

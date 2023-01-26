// MARK: - protocol example

import Foundation

protocol Describable {
    var describe: String { get }
}

// MARK: - example model
struct Person {
    let name: String
    let surname: String
    let id: String
}

struct Rectangle {
    let width: Int
    let height: Int
}

let peterGriffin = Person(name: "Peter", surname: "Griffin", id: "31242")
let square = Rectangle(width: 3, height: 3)


// MARK: - one way of implementing the protocol

extension Person: Describable {
    var describe: String {
        "Person(name: \(self.name), surname: \(self.surname), id: \(self.id)"
    }
}

extension Rectangle: Describable {
    var describe: String {
        "Rectangle(width: \(self.width), height: \(self.height)"
    }
}

print(peterGriffin.describe)
print(square.describe)


// MARK: - another way of implementing the protocol

//extension Person: Describable {
//  var describe: String {
//"""
//Person(
//  name: \"\(self.name)",
//  surname: \"\(self.surname)",
//  id: \"\(self.id)"
//)
//"""
//  }
//}
//
//print(peterGriffin.describe)



// You can say that you can extend Describable with:

//protocol Describable {
//    var describe: String { get }
//    var describePretty: String { get }
//}
//
//extension Person: Describable {
//    var describe: String {
//        "Person(name: \(self.name), surname: \(self.surname), id: \(self.id)"
//    }
//
//    var describePretty: String {
//        """
//        Person(
//          name: \"\(self.name)",
//          surname: \"\(self.surname)",
//          id: \"\(self.id)"
//        )
//        """
//    }
//}

// In that case we will need to implement describePretty for Rectangle as well.

























// MARK: - de-protocolize this by creating a generic struct

// This is how the compiler transforms the protocols as well during compile-time
// What we lose in code brevity, we gain in clarity and composition.
struct Describing<A> {
    var describe: (A) -> String
}

// MARK: - we create instances, which are called “witnesses”

let shortWitness = Describing<Person>(
    describe: {
        "Person(name: \($0.name), surname: \($0.surname), id: \($0.id)"
    }
)

shortWitness.describe(peterGriffin)


let prettyWitness = Describing<Person>(
    describe: {
        """
        Person(
            name: \"\($0.name)",
            surname: \"\($0.surname)",
            id: \"\($0.id)"
        )
        """
    }
)


prettyWitness.describe(peterGriffin)

// MARK: - Witnessing generic algorithms

func print<A>(tag: String, _ value: A, _ witness: Describing<A>) {
    print("[\(tag)] \(witness.describe(value))")
}

print(tag: "debug", peterGriffin, shortWitness)
print(tag: "debug", peterGriffin, prettyWitness)

// MARK: - when using protocols only

func print<A: Describable>(tag: String, _ value: A) {
    print("[\(tag)] \(value.describe)")
}

print(tag: "debug", peterGriffin)



















// MARK: - Witness ergonomics

extension Describing where A == Person {
    static var short = Self(
        describe: {
            "Person(name: \($0.name), surname: \($0.surname), id: \($0.id)"
        }
    )

    static let pretty = Self(
        describe: {
            """
            Person(
                name: \"\($0.name)",
                surname: \"\($0.surname)",
                id: \"\($0.id)"
            )
            """
        }
    )
}

print(tag: "debug", peterGriffin, .short)
print(tag: "debug", peterGriffin, .pretty)


extension Describing where A == Bool {
    static var short: Self {
        .init(
            describe: { $0 ? "t" : "f" }
        )
    }

    static var pretty: Self {
        .init(
            describe: { $0 ? "𝓣𝓻𝓾𝓮" : "𝓕𝓪𝓵𝓼𝓮" }
        )
    }
}

print(tag: "debug", true, .short)
print(tag: "debug", true, .pretty)

























// MARK: - Witnessing composition: contramap/pullback!
// MAP
// given Something<A>, and f(A) -> B, produces Something<B>

// CONTRAMAP
// given Something<A>, and f(B) -> A, produces Something<B>

extension Describing {
    func contramap<B>(_ f: @escaping (B) -> A) -> Describing<B> {
        return Describing<B>(
            describe: { b in
                self.describe(f(b))
            }
        )
    }
}

let secureShortWitness: Describing<Person> = shortWitness.contramap { originalPerson in
    Person(name: originalPerson.name, surname: originalPerson.surname, id: "********")
}

let securePrettyWitness: Describing<Person> = prettyWitness.contramap { originalPerson in
    Person(name: originalPerson.name, surname: originalPerson.surname, id: "********")
}

print(tag: "debug", peterGriffin, secureShortWitness)
print(tag: "debug", peterGriffin, securePrettyWitness)



// MARK: - Another example
struct Purchase {
    var amount: Double
    var shippingAmount: Double
}

struct Discounting<A> {
    let discounted: (A) -> Double
}

func printDiscount<A>(_ item: A, with discount: Discounting<A>) -> String {
    let discount = discount.discounted(item)
    return "Discount: \(discount)"
}

let purchase = Purchase(amount: 10, shippingAmount: 1.5)

extension Discounting {
    func pullback<B>(_ f: @escaping (B) -> A) -> Discounting<B> {
        .init { other -> Double in
            self.discounted(f(other))
        }
    }
}

extension Discounting where A == Double {
    static let tenPercentOff = Self { amount in
        amount * 0.9
    }

    static let fiveDollarsOff = Self { amount in
        amount - 5
    }
}

extension Discounting where A == Purchase {
    static let tenPercentOff: Self = Discounting<Double>
        .tenPercentOff
        .pullback({ purchase in
            purchase.amount
        })

    static let tenPercentOffShipping: Self = Discounting<Double>
        .tenPercentOff
        .pullback(\.shippingAmount)
}

printDiscount(purchase, with: .tenPercentOff)
printDiscount(purchase, with: .tenPercentOffShipping)

























// MARK: - What's the point?
protocol Downloadable {
    associatedtype Format
    func download() -> Format // for the JSON decoding: JSONDecoder().decode(Format.self, from: jsonData)
}

extension URL: Downloadable {
    func download() -> String {
        // Run some downloader like: URLSession.shared.dataTask(with: self)
        return "Downloaded String"
    }
//    func download() -> Data {
//
//    }
}

// Convert it to data type
struct Downloading<A, Format> {
    let download: (A) -> Format

    func pullback<B>(_ f: @escaping (B) -> A) -> Downloading<B, Format> {
        return Downloading<B, Format>(
            download: { b in
                self.download(f(b))
            }
        )
    }
}

struct Phone: Decodable {
    let year: String
}

extension Downloading where A == URL, Format: Decodable {
    static var live: Self {
        .init { url in
            let JSON = "{\"year\": \"2023\"}" // actually download this JSON using URLSession
            let jsonData = JSON.data(using: .utf8)!
            let object: Format = try! JSONDecoder().decode(Format.self, from: jsonData)
            return object
        }
    }

    static var mock: Self {
        .init { url in
            let jsonData = "{}".data(using: .utf8)!
            let object: Format = try! JSONDecoder().decode(Format.self, from: jsonData)
            return object
        }
    }
}

func download<Format>(url: URL, client: Downloading<URL, Format>) -> Format {
    client.download(url)
}

let url = URL(string: "https://www.apple.com")!
let phone: Phone = download(url: url, client: .live)
print(phone)


extension Downloading where A == String, Format: Decodable {
    static var live: Self {
        Downloading<URL, Format>.live.pullback { string in
            URL(string: string)!  // string -> URL
        }
    }
}

func download<Format>(urlString: String, client: Downloading<String, Format>) -> Format {
    client.download(urlString)
}

let anotherPhone: Phone = download(urlString: "https://www.apple.com", client: .live)
print(anotherPhone)


// MARK: Another example
struct PersistenceClient {
    let load: () -> Data?
    let save: (Data) -> (Bool)
}

extension PersistenceClient {
    static var live: Self {
        .init(
            load: {
                // actually load
                return Data()
            },
            save: { data in
                // actually save(data)
                let saveSuccessful = true
                return saveSuccessful
            }
        )
    }

    static var mock: Self {
        .init(
            load: {
                return Data()
            },
            save: { _ in
                return true
            }
        )
    }

    static var failureMock: Self {
        .init(
            load: {
                return nil
            },
            save: { _ in
                return false
            }
        )
    }
}

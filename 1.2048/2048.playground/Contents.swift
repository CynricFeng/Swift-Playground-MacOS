import PlaygroundSupport
import AppKit
import GameplayKit

enum Orientation {
    case vertical
    case horizon
}

enum Direction : Int{
    case forward = 1
    case backward = -1
}


struct Position : Equatable{
    let x : Int
    let y : Int
    
    func previousPosition(direction:Direction, orientation:Orientation) -> Position {
        switch orientation {
        case .vertical:
            return Position(x: x, y: y - direction.rawValue)
        case .horizon:
            return Position(x: x - direction.rawValue, y: y)
        }
    }
}

struct Style {
    let boardBackgroundColor = #colorLiteral(red: 0.7437869906, green: 0.6771768928, blue: 0.6207157969, alpha: 1)
    let emptyBlockBackgroundColor = #colorLiteral(red: 0.8128815293, green: 0.7559809089, blue: 0.6993753314, alpha: 1)
    
    let blockBackgroundColors = [
        #colorLiteral(red: 0.978682816, green: 0.964609921, blue: 0.9470840096, alpha: 1), #colorLiteral(red: 0.9409049749, green: 0.893355608, blue: 0.8499074578, alpha: 1), #colorLiteral(red: 0.9386757016, green: 0.8782688975, blue: 0.7727541327, alpha: 1), #colorLiteral(red: 0.9914368987, green: 0.6849566102, blue: 0.4334937632, alpha: 1), #colorLiteral(red: 1, green: 0.4540016651, blue: 0.3347376585, alpha: 1),
        #colorLiteral(red: 1, green: 0.3136093616, blue: 0.1563289165, alpha: 1), #colorLiteral(red: 0.9764705882, green: 0.3843137255, blue: 0.2980392157, alpha: 1), #colorLiteral(red: 0.8901960784, green: 0.2549019608, blue: 0.1764705882, alpha: 1), #colorLiteral(red: 0.9450980392, green: 0.8235294118, blue: 0.3568627451, alpha: 1),
        #colorLiteral(red: 0.9333333333, green: 0.7921568627, blue: 0.231372549, alpha: 1), #colorLiteral(red: 0.8745098039, green: 0.7137254902, blue: 0.1333333333, alpha: 1), #colorLiteral(red: 0.9137254902, green: 0.7333333333, blue: 0.1921568627, alpha: 1), #colorLiteral(red: 0.9098039216, green: 0.737254902, blue: 0.03921568627, alpha: 1)
    ]
    
    let blockFontColors = [
        #colorLiteral(red: 0.4733663797, green: 0.4306218028, blue: 0.3914675713, alpha: 1), #colorLiteral(red: 0.978682816, green: 0.964609921, blue: 0.9470840096, alpha: 1)
    ]
    
    /// get the color of the block's background according to the color index in the blockBackgroundColors table.
    func blockBackgroundColor(colorIndex: Int) -> NSColor {
        return colorIndex < blockBackgroundColors.count ? blockBackgroundColors[colorIndex] : blockBackgroundColors.last ?? #colorLiteral(red: 0.9098039216, green: 0.737254902, blue: 0.03921568627, alpha: 1)
    }
    
    /// get tht color of the font
    func fontColor(fontIndex: Int) -> NSColor {
        return fontIndex > 2 ? blockFontColors[1] : blockFontColors[0]
    }
}

struct BoardSizeConfig {
    let blockNumber = 4
    let blockCount  = 16
    let boardSize   = CGSize(width: 290, height: 290)
    let blockSize    = CGSize(width: 60, height: 60)
    let borderSize  = CGSize(width: 10, height: 10)
}

let style = Style()
let boardConfig = BoardSizeConfig()


class Block : Equatable {
    static func == (lhs: Block, rhs: Block) -> Bool {
        return lhs.number == rhs.number && lhs.position == rhs.position
    }
    
    var number : Int = 0 {
        didSet {
            updateView()
        }
    }
    
    var numberText : String {
        return number == 0 ? "NO" : "\(1 << number)"
    }
    
    var isEmpty : Bool {
        return number == 0
    }
    
    var numberLength : Int {
        return numberText.count
    }
    
    let view : NSTextView = NSTextView(frame: .zero)
    let numberView : NSTextField = NSTextField(frame: .zero)
    
    var position : Position {
        didSet {
            guard let board = self.board else {
                return
            }
            let pos = board.getPosition(x: self.position.x, y: self.position.y)
            self.topConstraint?.constant = pos.y
            self.leftConstraint?.constant = pos.x
        }
    }
    
    var board : Board?
    var topConstraint : NSLayoutConstraint?
    var leftConstraint : NSLayoutConstraint?
    
    init(value: Int, position : Position = Position(x: 0, y: 0)) {
        self.position = position
        
        view.alignment = .center
        view.isFieldEditor = false
        view.isSelectable = false
        view.isEditable = false
        
        numberView.isSelectable = false
        numberView.isEditable = false
        numberView.isBezeled = false
        
        view.translatesAutoresizingMaskIntoConstraints = false
        numberView.translatesAutoresizingMaskIntoConstraints = false
        
        view.heightAnchor.constraint(equalToConstant: boardConfig.blockSize.width).isActive = true
        view.widthAnchor.constraint(equalToConstant: boardConfig.blockSize.width).isActive = true
        
        self.number = value
        updateView()
    }
    
    func fontSize(for index: Int) -> CGFloat {
        if index > 4 {
            return 18
        }
        else if index > 3 {
            return 20
        }
        return 30
    }
    
    func updateView() {
        view.backgroundColor = style.blockBackgroundColor(colorIndex: number)
        
        numberView.stringValue = numberText
        numberView.font = NSFont.boldSystemFont(ofSize: fontSize(for: numberLength))
        numberView.textColor = style.fontColor(fontIndex: number)
        numberView.backgroundColor = style.blockBackgroundColor(colorIndex: number)
        numberView.sizeToFit()

    }
    
    func moveTo(position: Position) {
        self.position = position
    }
    
    func mergeTo(position: Position) {
        moveTo(position: position)
        self.number += 1
    }
    
    func addTo(board: Board) {
        guard self.board == nil else {
            return
        }
                
        self.board = board
        let boardView = board.boardView
        view.addSubview(numberView)
        boardView.addSubview(view)
        
        let pos = board.getPosition(x: self.position.x, y: self.position.y)
        topConstraint = view.topAnchor.constraint(equalTo: boardView.topAnchor, constant: pos.y)
        leftConstraint = view.leftAnchor.constraint(equalTo: boardView.leftAnchor, constant: pos.x)
        topConstraint?.isActive = true
        leftConstraint?.isActive = true
        
        numberView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        numberView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        
        view.layer?.cornerRadius = 3
    }
    
    func removeFromBoard() {
        self.view.removeFromSuperview()
    }
    
    func createPreivousEmptyBlock(direction: Direction, orientation: Orientation) -> Block {
        let pos = self.position.previousPosition(direction: direction, orientation: orientation)
        return Block(value: 0, position: pos)
    }
    
}


/// Mark: Board

class Board {
    
    let boardView: NSView
    var blocksArray = [Block]()
    
    init() {
        boardView = NSView(frame: NSRect(x: 0, y: 0, width: boardConfig.boardSize.width, height: boardConfig.boardSize.height))
        boardView.layer?.cornerRadius = 6
        boardView.layer?.backgroundColor = style.boardBackgroundColor.cgColor
    }
    
    
    func getPosition(x: Int, y: Int) -> CGPoint {
        let offsetX = boardConfig.borderSize.width
        let offsetY = boardConfig.borderSize.height
        
        let oneBlockWidth = boardConfig.blockSize.width +  boardConfig.borderSize.width
        let oneBlockHeight = boardConfig.blockSize.height + boardConfig.borderSize.height
        
        return CGPoint(x: offsetX + oneBlockWidth * CGFloat(x), y: offsetY + oneBlockHeight * CGFloat(y))
    }
    
    func addTo(view : NSView){
        view.addSubview(self.boardView)
        boardView.widthAnchor.constraint(equalToConstant: boardConfig.boardSize.width).isActive = true
        boardView.heightAnchor.constraint(equalTo: boardView.widthAnchor).isActive = true
        boardView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        boardView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
    }
    
    func generateBlock() {
        guard blocksArray.count <= boardConfig.blockCount else {
            print("There is no space to put a new block.")
            return
        }
        
        var blocksList : [(Int, Int)?] = Array(repeating: nil, count: boardConfig.blockCount)
        for x in 0..<boardConfig.blockNumber {
            for y in 0..<boardConfig.blockNumber {
                blocksList[x + y * boardConfig.blockNumber] = (x,y)
            }
        }
        
        for block in blocksArray {
            blocksList[block.position.x + block.position.y * boardConfig.blockNumber] = nil
        }
        
        let candidate = blocksList.compactMap {$0}
        let chosenCandidateIndex = arc4random_uniform(UInt32(candidate.count))
        let candidateValue = arc4random_uniform(UInt32(10)) > 8 ? 2 : 1
        
        let (x, y) = candidate[Int(chosenCandidateIndex)]
        let block = Block(value: candidateValue, position: Position(x: x, y: y))
                
        block.addTo(board: self)
        blocksArray.append(block)
    }
    
    func removeBlock(block: Block){
        if let index = blocksArray.firstIndex(where: {$0 == block}) {
            blocksArray.remove(at: index)
            block.removeFromBoard()
        }
    }
    
    func buildBoard() {
        for x in 0..<boardConfig.blockNumber {
            for y in 0..<boardConfig.blockNumber {
                let layer = CALayer()
                layer.frame = CGRect(origin: getPosition(x: x, y: y), size: boardConfig.blockSize)
                layer.backgroundColor = style.emptyBlockBackgroundColor.cgColor
                layer.cornerRadius = 3
                boardView.layer?.addSublayer(layer)
                
            }
        }
        
        generateBlock()
        generateBlock()
    }
    
    func checkMovement(direction: Direction, orientation: Orientation) -> Bool {
        var move = false
        var blocksList = [Block]()
        
        for y in 0..<boardConfig.blockNumber {
            for x in 0..<boardConfig.blockNumber {
                let block = Block(value: 0, position: Position(x: x, y: y))
                blocksList.append(block)
            }
        }
        
        for block in blocksArray {
            blocksList[block.position.x + block.position.y * boardConfig.blockNumber] = block
        }
        
        for i in 0..<boardConfig.blockNumber {
            var lastEmptyBlock : Block? = nil
            var lastMergableBlock : Block? = nil
            for j in 0..<boardConfig.blockNumber {
                let steps = (direction == .forward ? (boardConfig.blockNumber - 1 - j) : j)
                let x = (orientation == .horizon ? steps : i)
                let y = (orientation == .horizon ? i : steps)
                
                let block = blocksList[x + y * boardConfig.blockNumber]
                
                if !block.isEmpty {
                    if let mergableBlock = lastMergableBlock, mergableBlock.number == block.number {
                        block.mergeTo(position: mergableBlock.position)
                        removeBlock(block: mergableBlock)
                        lastMergableBlock = nil
                        lastEmptyBlock = block.createPreivousEmptyBlock(direction: direction, orientation: orientation)
                        move = true
                        continue
                    }
                    if let emptyBlock = lastEmptyBlock {
                        block.moveTo(position: emptyBlock.position)
                        lastEmptyBlock = block.createPreivousEmptyBlock(direction: direction, orientation: orientation)
                        move = true
                    }
                    lastMergableBlock = block
                }
                else {
                    if lastEmptyBlock == nil {
                        lastEmptyBlock = block
                    }
                }
            }
        }
        return move
    }
    
    func moveBlock(direction: Direction, orientation: Orientation) {
        let move = checkMovement(direction: direction, orientation: orientation)
        if move {
            generateBlock()
        }
    }
}

class GameViewController: NSViewController,  NSTableViewDataSource, NSTableViewDelegate {
    let board = Board()

    override func loadView() {
        self.view = NSView(frame: NSRect(x: 0, y: 0, width: boardConfig.boardSize.width, height: boardConfig.boardSize.height))
        view.wantsLayer = true
    }

    override func viewDidLoad() {
        let view = self.view

        view.layer!.backgroundColor = style.boardBackgroundColor.cgColor
        view.layer?.cornerRadius = 6
        
    
        board.addTo(view: view)
        board.buildBoard()
        
        
        // Why this work
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) {
            (event) -> NSEvent? in self.keyDown(with: event); return event
        }
    }
    
      
    override func keyDown(with theEvent: NSEvent) {
        switch theEvent.keyCode {
        case 126:
            // print("Up")
            
            board.moveBlock(direction: .backward, orientation: .vertical)
//            board.generateBlock()
        case 125:
            // print("Down")
            board.moveBlock(direction: .forward, orientation: .vertical)
        case 123:
            // print("Left")
            board.moveBlock(direction: .backward, orientation: .horizon)
        case 124:
            // print("Right")
            board.moveBlock(direction: .forward, orientation: .horizon)
        default:
            break
        }
    }
    
    
}



let controller = GameViewController()
PlaygroundPage.current.liveView = controller
